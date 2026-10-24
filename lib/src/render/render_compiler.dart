import 'package:collection/collection.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/render/render_nodes.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

/// Check if the names passed are accessed undeclared.
///
/// The return value is a set of all the undeclared names from the sequence of
/// names found.
Set<String> findUndeclared(Iterable<Node> nodes, Set<String> names) {
  var visitor = UndeclaredNameVisitor(names);

  try {
    for (var node in nodes) {
      node.accept(visitor, null);
    }
  } on VisitorExit {
    // ...
  }

  return visitor.undeclared;
}

final class VisitorExit implements Exception;

final class CompilerExit implements Exception;

final class DependencyFinderVisitor extends ChildVisitor<void> {
  new() : filters = <String>{}, tests = <String>{};

  final Set<String> filters;

  final Set<String> tests;

  @override
  void visitFilter(Filter node, void context) {
    visitChildren(node, context);
    filters.add(node.name);
  }

  @override
  void visitTest(Test node, void context) {
    visitChildren(node, context);
    tests.add(node.name);
  }

  @override
  void visitBlock(Block node, void context) {
    // Stop visiting at blocks.
  }
}

final class UndeclaredNameVisitor extends ChildVisitor<void> {
  new(Set<String> names) : names = names.toSet(), undeclared = <String>{};

  final Set<String> names;

  final Set<String> undeclared;

  // Expressions

  @override
  void visitName(Name node, void context) {
    if (node.context == AssignContext.load && names.contains(node.name)) {
      undeclared.add(node.name);

      if (const SetEquality<String>().equals(names, undeclared)) {
        throw VisitorExit();
      }
    } else {
      names.remove(node.name);
    }
  }

  // Statements

  @override
  void visitBlock(Block node, void context) {
    // Stop visiting at blocks.
  }
}

final class MacroRef {
  new(this.node);

  final MacroCall node;

  bool accessesCaller = false;

  bool accessesKwargs = false;

  bool accessesVarargs = false;
}

/// Holds compile time information for [RenderCompiler].
final class Frame {
  new({this.parent})
    : requireOutputCheck = parent?.requireOutputCheck ?? false,
      blockBuffer = parent?.blockBuffer,
      block = parent?.block,
      softFrame = parent?.softFrame ?? false;

  final Frame? parent;

  bool requireOutputCheck;

  RExpression? blockBuffer;

  String? block;

  bool toplevel = false;

  bool rootlevel = false;

  bool loopFrame = false;

  bool blockFrame = false;

  bool softFrame = false;

  Frame copy() {
    return Frame(parent: parent)
      ..requireOutputCheck = requireOutputCheck
      ..blockBuffer = blockBuffer
      ..block = block
      ..toplevel = toplevel
      ..rootlevel = rootlevel
      ..loopFrame = loopFrame
      ..blockFrame = blockFrame
      ..softFrame = softFrame;
  }

  Frame inner({bool isolated = false}) {
    if (isolated) {
      return Frame();
    }

    return Frame(parent: this);
  }

  Frame soft() {
    return copy()
      ..rootlevel = false
      ..softFrame = true;
  }
}

@doNotStore
base class RenderCompiler extends ThrowingVisitor<Frame, RenderNode> {
  new(this.environment, {this.path})
    : blocks = <String, Block>{},
      extendsSoFar = 0,
      hasKnownExtends = false;

  final Environment environment;

  final String? path;

  final Map<String, Block> blocks;

  int extendsSoFar;

  bool hasKnownExtends;

  Never fail(String message, [int? line]) {
    throw TemplateAssertionError(message, line: line, path: path);
  }

  // Node

  T visitNode<T extends RenderNode?>(Node? node, Frame context) {
    return node?.accept(this, context) as T;
  }

  List<T> visitNodes<T extends RenderNode>(List<Node> nodes, Frame context) {
    T generator(int index) {
      return visitNode<T>(nodes[index], context);
    }

    return List<T>.generate(nodes.length, generator);
  }

  List<T>? visitNullNodes<T extends RenderNode>(
    List<Node>? nodes,
    Frame context,
  ) {
    if (nodes == null) {
      return null;
    }

    return visitNodes<T>(nodes, context);
  }

  List<RenderNode> blockVisit(List<Node> nodes, Frame context) {
    var result = <RenderNode>[];

    try {
      for (var node in nodes) {
        result.add(visitNode<RenderNode>(node, context));
      }
    } on CompilerExit {
      // Stop processing unreachable nodes in this block.
    }

    return result;
  }

  (Frame, MacroRef) macroBody(MacroCall node, Frame context) {
    var frame = context.inner()..requireOutputCheck = false;
    var macroRef = MacroRef(node);

    var explicitCallerPositional = false;
    var skipSpecialParams = <String>{};

    for (var argument in node.positional) {
      if (argument case Name(:var name)) {
        if (name == 'caller') {
          explicitCallerPositional = true;
        }

        if (name == 'kwargs' || name == 'varargs') {
          skipSpecialParams.add(name);
        }
      }
    }

    for (var named in node.named) {
      if (named.argument case Name(:var name)) {
        if (name == 'kwargs' || name == 'varargs') {
          skipSpecialParams.add(name);
        }
      }
    }

    var undeclared = findUndeclared(node.nodes, const <String>{
      'caller',
      'kwargs',
      'varargs',
    });

    if (undeclared.contains('caller')) {
      if (explicitCallerPositional) {
        fail(
          'When defining macros or call blocks the special "caller" '
          'argument must be omitted or be given a default.',
        );
      }

      macroRef.accessesCaller = true;
    }

    if (undeclared.contains('kwargs') &&
        !skipSpecialParams.contains('kwargs')) {
      macroRef.accessesKwargs = true;
    }

    if (undeclared.contains('varargs') &&
        !skipSpecialParams.contains('varargs')) {
      macroRef.accessesVarargs = true;
    }

    return (frame, macroRef);
  }

  RMacroDef macroDef(MacroRef macroRef, Frame context) {
    var node = macroRef.node;
    var positional = <String>[];
    var named = <(String, RExpression)>[];
    var explicitCallerNamed = false;

    for (var argument in node.positional) {
      positional.add((argument as Name).name);
    }

    for (var item in node.named) {
      var name = (item.argument as Name).name;

      if (name == 'caller') {
        explicitCallerNamed = true;
      }

      named.add((name, visitNode<RExpression>(item.defaultValue, context)));
    }

    if (macroRef.accessesCaller && !explicitCallerNamed) {
      named.add(('caller', const RValue(null)));
    }

    var body = blockVisit(node.nodes, context);

    return RMacroDef(
      name: node is Macro ? node.name : 'caller',
      positional: positional,
      named: named,
      accessesCaller: macroRef.accessesCaller,
      accessesKwargs: macroRef.accessesKwargs,
      accessesVarargs: macroRef.accessesVarargs,
      nodes: body,
    );
  }

  // Helpers

  @override
  RenderNode visitKeyword(Keyword node, Frame context) {
    throw UnimplementedError();
  }

  @override
  RenderNode visitPair(Pair node, Frame context) {
    throw UnimplementedError();
  }

  @override
  RenderNode visitOperand(Operand node, Frame context) {
    throw UnimplementedError();
  }

  // Expressions

  @override
  RList visitArray(Array node, Frame context) {
    var values = visitNodes<RExpression>(node.values, context);
    return RList(values);
  }

  @override
  RGetAttribute visitAttribute(Attribute node, Frame context) {
    var value = visitNode<RExpression>(node.value, context);
    return RGetAttribute(node.attribute, value);
  }

  @override
  RCall visitCall(Call node, Frame context) {
    if (node.value case Name(name: 'namespace', context: AssignContext.load)) {
      var calling = node.calling;
      var values = <RExpression>[
        for (var argument in calling.arguments)
          visitNode<RExpression>(argument, context),
      ];

      if (calling.keywords.isNotEmpty) {
        var pairs = <RMapPair>[
          for (var keyword in calling.keywords)
            RMapPair(
              RValue(keyword.key),
              visitNode<RExpression>(keyword.value, context),
            ),
        ];

        values.add(RMap(pairs));
      }

      return RCall(visitNode<RExpression>(node.value, context), <RExpression>[
        if (values.isNotEmpty) RList(values),
      ], const <Symbol, RExpression>{});
    }

    var function = visitNode<RExpression>(node.value, context);
    var positional = visitNodes<RExpression>(node.calling.arguments, context);

    if (node.value case Attribute(
      attribute: 'cycle',
      value: Name(name: 'loop', context: AssignContext.load),
    )) {
      if (positional.length > 1) {
        positional = <RExpression>[RList(positional)];
      }
    }

    var named = <Symbol, RExpression>{
      for (var keyword in node.calling.keywords)
        Symbol(keyword.key): visitNode<RExpression>(keyword.value, context),
    };

    return RCall(function, positional, named);
  }

  @override
  RenderNode visitCalling(Calling node, Frame context) {
    // TODO(render): update error message.
    throw UnsupportedError('$Calling');
  }

  @override
  RExpression visitCompare(Compare node, Frame context) {
    var value = visitNode<RExpression>(node.value, context);
    var operands = <RCompareOperand>[];

    for (var operand in node.operands) {
      var value = visitNode<RExpression>(operand.value, context);
      operands.add(RCompareOperand(operand.operator, value));
    }

    return RCompare(value, operands);
  }

  @override
  RJoin visitConcat(Concat node, Frame context) {
    var values = visitNodes<RExpression>(node.values, context);
    return RJoin(values);
  }

  @override
  RCondition visitCondition(Condition node, Frame context) {
    var condFrame = context.soft();
    var test = visitNode<RExpression>(node.test, condFrame);
    var trueValue = visitNode<RExpression>(node.trueValue, condFrame);
    var falseValue = visitNode<RExpression?>(node.falseValue, condFrame);
    return RCondition(test, trueValue, falseValue);
  }

  @override
  RValue visitConstant(Constant node, Frame context) {
    return RValue(node.value);
  }

  @override
  RMap visitDict(Dict node, Frame context) {
    var pairs = <RMapPair>[
      for (var pair in node.pairs)
        RMapPair(
          visitNode<RExpression>(pair.key, context),
          visitNode<RExpression>(pair.value, context),
        ),
    ];

    return RMap(pairs);
  }

  @override
  RFilter visitFilter(Filter node, Frame context) {
    var name = node.name;

    if (!environment.filters.containsKey(name) && !context.softFrame) {
      fail("No filter named '$name'.");
    }

    RExpression expression;

    if (node.expression case var expr?) {
      expression = visitNode<RExpression>(expr, context);
    } else if (context.blockBuffer case var buffer?) {
      expression = buffer;
    } else {
      fail('Filter expected an expression.');
    }

    if (name == 'map') {
      var args = visitNodes<RExpression>(node.calling.arguments, context);
      var kwargs = <RMapPair>[
        for (var keyword in node.calling.keywords)
          RMapPair(
            RValue(keyword.key),
            visitNode<RExpression>(keyword.value, context),
          ),
      ];

      return RFilter(name, <RExpression>[
        expression,
        RList(args),
        RMap(kwargs),
      ], const <Symbol, RExpression>{});
    }

    var positional = <RExpression>[
      expression,
      ...visitNodes<RExpression>(node.calling.arguments, context),
    ];

    var named = <Symbol, RExpression>{
      for (var keyword in node.calling.keywords)
        Symbol(keyword.key): visitNode<RExpression>(keyword.value, context),
    };

    return RFilter(name, positional, named);
  }

  @override
  RenderNode visitItem(Item node, Frame context) {
    if (node.key case Slice sliceNode) {
      var start = visitNode<RExpression?>(sliceNode.start, context);
      var stop = visitNode<RExpression?>(sliceNode.stop, context);
      var step = visitNode<RExpression?>(sliceNode.step, context);
      var value = visitNode<RExpression>(node.value, context);
      return RGetSlice(value, start, stop, step);
    }

    var key = visitNode<RExpression>(node.key, context);
    var value = visitNode<RExpression>(node.value, context);
    return RGetItem(key, value);
  }

  @override
  RLogical visitLogical(Logical node, Frame context) {
    var left = visitNode<RExpression>(node.left, context);
    var right = visitNode<RExpression>(node.right, context);
    return RLogical(left, right, node.operator);
  }

  @override
  RenderNode visitName(Name node, Frame context) {
    if (node.context == AssignContext.load) {
      return RLoad(node.name);
    }

    return RName(node.name);
  }

  @override
  RNsRef visitNsRef(NsRef node, Frame context) {
    return RNsRef(node.name, node.attribute);
  }

  @override
  RScalar visitScalar(Scalar node, Frame context) {
    var left = visitNode<RExpression>(node.left, context);
    var right = visitNode<RExpression>(node.right, context);
    return RScalar(left, right, node.operator);
  }

  @override
  RenderNode visitSlice(Slice node, Frame context) {
    // TODO(render): update error message.
    throw UnsupportedError('$visitSlice');
  }

  @override
  RTest visitTest(Test node, Frame context) {
    var name = node.name;

    if (!environment.tests.containsKey(name) && !context.softFrame) {
      fail("No test named '$name'.");
    }

    var expression = visitNode<RExpression>(node.expression, context);
    var positional = <RExpression>[
      expression,
      ...visitNodes<RExpression>(node.calling.arguments, context),
    ];

    var named = <Symbol, RExpression>{
      for (var keyword in node.calling.keywords)
        Symbol(keyword.key): visitNode<RExpression>(keyword.value, context),
    };

    return RTest(name, positional, named);
  }

  @override
  RList visitTuple(Tuple node, Frame context) {
    var values = visitNodes<RExpression>(node.values, context);
    return RList(values);
  }

  @override
  RUnary visitUnary(Unary node, Frame context) {
    var value = visitNode<RExpression>(node.value, context);
    return RUnary(value, node.operator);
  }

  // Statements

  RenderNode _compileAssign(
    Expression target,
    RExpression expression,
    Frame context,
  ) {
    if (target case Name name when name.canAssign) {
      return RAssign(name.name, expression);
    }

    if (target case NsRef nsRef) {
      return RAssignAttribute(nsRef.name, nsRef.attribute, expression);
    }

    if (target.canAssign) {
      return RAssignTargets(
        visitNode<RExpression>(target, context),
        expression,
      );
    }

    fail("Can't assign to $target.");
  }

  @override
  RenderNode visitAssign(Assign node, Frame context) {
    var expression = visitNode<RExpression>(node.value, context);
    return _compileAssign(node.target, expression, context);
  }

  @override
  RenderNode visitAssignBlock(AssignBlock node, Frame context) {
    var blockFrame = context.inner()..requireOutputCheck = false;
    var nodes = blockVisit(node.nodes, blockFrame);
    RExpression expression = RBlockExpression(nodes);

    if (node.filter case var filterNode?) {
      blockFrame.blockBuffer = expression;
      expression = visitFilter(filterNode, blockFrame);
    }

    return _compileAssign(node.target, expression, context);
  }

  @override
  RenderNode visitBlock(Block node, Frame context) {
    var checkParent = false;

    if (context.toplevel) {
      if (hasKnownExtends) {
        return const REmpty();
      }

      if (extendsSoFar > 0) {
        checkParent = true;
      }
    }

    return RCallBlock(node.name, checkParent: checkParent);
  }

  @override
  RenderNode visitCallBlock(CallBlock node, Frame context) {
    if (context.requireOutputCheck && hasKnownExtends) {
      return const REmpty();
    }

    var (callFrame, macroRef) = macroBody(node, context);
    var callerDef = macroDef(macroRef, callFrame);
    var call = visitCall(node.call, context);

    return RCallerBlock(
      call,
      callerDef,
      checkParent: context.requireOutputCheck && !hasKnownExtends,
    );
  }

  @override
  RenderNode visitData(Data node, Frame context) {
    if (context.requireOutputCheck && hasKnownExtends) {
      return const REmpty();
    }

    return RData(node.data);
  }

  @override
  RDo visitDo(Do node, Frame context) {
    var expressions = visitNodes<RExpression>(node.expressions, context);
    return RDo(expressions);
  }

  @override
  RExtends visitExtends(Extends node, Frame context) {
    if (!context.toplevel) {
      fail('Cannot use extend from a non top-level scope.');
    }

    if (extendsSoFar > 0 && hasKnownExtends) {
      fail('Extended multiple times.');
    }

    var template = visitNode<RExpression>(node.template, context);

    if (context.rootlevel) {
      hasKnownExtends = true;
    }

    extendsSoFar += 1;
    return RExtends(template);
  }

  @override
  RenderNode visitFilterBlock(FilterBlock node, Frame context) {
    if (context.requireOutputCheck && hasKnownExtends) {
      return const REmpty();
    }

    var filterFrame = context.inner()..requireOutputCheck = false;
    var nodes = blockVisit(node.nodes, filterFrame);
    filterFrame.blockBuffer = RBlockExpression(nodes);
    var filter = visitFilter(node.filter, filterFrame);

    if (context.requireOutputCheck) {
      return ROutput(<RenderNode>[filter], checkParent: true);
    }

    return filter;
  }

  @override
  RFor visitFor(For node, Frame context) {
    var loopFrame = context.inner()..loopFrame = true;
    var testFrame = context.inner();
    var elseFrame = context.inner();

    var extendedLoop =
        node.recursive ||
        findUndeclared(node.nodes, const <String>{'loop'}).contains('loop') ||
        node.findAll<Block>().any((block) => block.scoped);

    var targetNames = <Name>[
      if (node.target case Name name) name,
      ...node.target.findAll<Name>(),
    ];

    for (var name in targetNames) {
      if (name.context == AssignContext.store && name.name == 'loop') {
        fail("Can't assign to special loop variable in for-loop target.");
      }
    }

    var target = visitNode<RExpression>(node.target, loopFrame);
    var iterable = visitNode<RExpression>(node.iterable, context);
    var test = visitNode<RExpression?>(node.test, testFrame);
    var nodes = blockVisit(node.nodes, loopFrame);
    List<RenderNode> elseNodes;

    if (node.elseNodes case var nodes?) {
      elseNodes = blockVisit(nodes, elseFrame);
    } else {
      elseNodes = const <RenderNode>[];
    }

    return RFor(
      target,
      iterable,
      nodes,
      elseNodes,
      test: test,
      recursive: node.recursive,
      extendedLoop: extendedLoop,
    );
  }

  @override
  RFromImport visitFromImport(FromImport node, Frame context) {
    var template = visitNode<RExpression>(node.template, context);
    return RFromImport(template, node.names, withContext: node.withContext);
  }

  @override
  RIf visitIf(If node, Frame context) {
    var ifFrame = context.soft();

    IfCase compile(If node, Frame frame) {
      var test = visitNode<RExpression>(node.test, frame);
      var nodes = blockVisit(node.nodes, frame);
      return IfCase(test, nodes);
    }

    var ifCases = <IfCase>[compile(node, ifFrame)];

    if (node.elseIfNodes case var elseIfNodes?) {
      for (var elseIfNode in elseIfNodes) {
        ifCases.add(compile(elseIfNode, ifFrame));
      }
    }

    List<RenderNode> elseNodes;

    if (node.elseNodes case var nodes?) {
      elseNodes = blockVisit(nodes, ifFrame);
    } else {
      elseNodes = const <RenderNode>[];
    }

    return RIf(ifCases, elseNodes);
  }

  @override
  RImport visitImport(Import node, Frame context) {
    var template = visitNode<RExpression>(node.template, context);
    return RImport(template, node.target, withContext: node.withContext);
  }

  @override
  RInclude visitInclude(Include node, Frame context) {
    var template = visitNode<RExpression>(node.template, context);
    return RInclude(
      template,
      ignoreMissing: node.ignoreMissing,
      withContext: node.withContext,
    );
  }

  @override
  RMacro visitMacro(Macro node, Frame context) {
    var (macroFrame, macroRef) = macroBody(node, context);
    return RMacro(macroDef(macroRef, macroFrame));
  }

  @override
  RenderNode visitOutput(Output node, Frame context) {
    if (context.requireOutputCheck) {
      if (hasKnownExtends) {
        return const REmpty();
      }

      var nodes = visitNodes<RenderNode>(node.nodes, context);
      return ROutput(nodes, checkParent: true);
    }

    var nodes = visitNodes<RenderNode>(node.nodes, context);
    return ROutput(nodes);
  }

  @override
  RTemplateNode visitTemplateNode(TemplateNode node, Frame context) {
    var haveExtends = node.find<Extends>() != null;

    for (var block in node.findAll<Block>()) {
      if (blocks.containsKey(block.name)) {
        fail("Block '${block.name}' defined twice.");
      }

      blocks[block.name] = block;
    }

    var haveSelf = findUndeclared(node.nodes, const <String>{
      'self',
    }).contains('self');

    var rootFrame = Frame()
      ..toplevel = true
      ..rootlevel = true
      ..requireOutputCheck = haveExtends && !hasKnownExtends;

    var nodes = blockVisit(node.nodes, rootFrame);
    var compiledBlocks = <RBlock>[];

    for (var MapEntry(key: name, value: block) in blocks.entries) {
      var blockFrame = Frame()
        ..blockFrame = true
        ..block = name;

      var undeclared = findUndeclared(block.nodes, const <String>{
        'self',
        'super',
      });

      var blockNodes = blockVisit(block.nodes, blockFrame);

      compiledBlocks.add(
        RBlock(
          name: name,
          scoped: block.scoped,
          required: block.required,
          hasSuper: undeclared.contains('super'),
          hasSelf: undeclared.contains('self'),
          nodes: blockNodes,
        ),
      );
    }

    return RTemplateNode(
      nodes,
      blocks: compiledBlocks,
      haveExtends: haveExtends,
      haveSelf: haveSelf,
    );
  }

  @override
  RenderNode visitTryCatch(TryCatch node, Frame context) {
    var nodes = blockVisit(node.nodes, context);
    var exception = node.exception?.name;
    var catchNodes = blockVisit(node.catchNodes, context);
    return RTryCatch(nodes, exception, catchNodes);
  }

  @override
  RWith visitWith(With node, Frame context) {
    var withFrame = context.inner();
    var targets = visitNodes<RExpression>(node.targets, withFrame);
    var values = visitNodes<RExpression>(node.values, context);
    var nodes = blockVisit(node.nodes, withFrame);
    return RWith(targets, values, nodes);
  }

  static RTemplateNode compile(
    TemplateNode node,
    Environment environment, {
    String? path,
  }) {
    var compiler = RenderCompiler(environment, path: path);
    return compiler.visitTemplateNode(node, Frame());
  }
}
