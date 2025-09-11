import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

// TODO(renderer): Rename to `StringSinkRendererCompiler`
// and move to `renderer.dart`. Add `ContextNode` for `ContextCallback`s.
@doNotStore
class RuntimeCompiler implements Visitor<void, Node> {
  RuntimeCompiler()
    : _imports = <String>{},
      _macros = <String>{},
      _inMacro = false;

  final Set<String> _imports;

  final Set<String> _macros;

  bool _inMacro;

  T visitNode<T extends Node?>(Node? node, void context) {
    return node?.accept(this, context) as T;
  }

  List<T>? visitNodes<T extends Node>(List<Node>? nodes, void context) {
    if (nodes == null) {
      return null;
    }

    return <T>[for (var node in nodes) visitNode<T>(node, context)];
  }

  // Expressions

  @override
  Array visitArray(Array node, void context) {
    return node.copyWith(values: visitNodes<Expression>(node.values, context));
  }

  @override
  Node visitAttribute(Attribute node, void context) {
    // Modifies Template AST from `self.prop` to `self['prop']`.
    if (node.value case Name(name: 'self')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode<Expression>(node.value, context),
      );
    }

    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Call visitCall(Call node, void context) {
    // Modifies Template AST from `loop.cycle(first, second)`
    // to `loop['cycle']([first, second])`, which matches
    // [LoopContext.cycle] definition.
    //
    // TODO(compiler): check name arguments
    if (node.value case Attribute(attribute: 'cycle', value: var value)) {
      if (value case Name(name: 'loop')) {
        var calling = visitNode<Calling>(node.calling, context);
        var arguments = calling.arguments.length == 1
            ? calling.arguments
            : <Expression>[Array(values: calling.arguments)];

        return node.copyWith(
          value: Item(
            key: Constant(value: 'cycle'),
            value: value,
          ),
          calling: Calling(
            arguments: visitNodes<Expression>(arguments, context)!,
          ),
        );
      }
    }

    // Modifies Template AST from `namespace(map1, ..., key1=value1, ...)`
    // to `namespace([map1, ..., {'key1': value1, ...}])`, to match [namespace]
    // definition.
    //
    // TODO(compiler): handle super call
    if (node.value case Name(name: var name)) {
      if (name == 'namespace') {
        var calling = visitNode<Calling>(node.calling, context);
        var values = calling.arguments.toList();

        if (calling.keywords.isNotEmpty) {
          var pairs = <Pair>[
            for (var (:key, :value) in calling.keywords)
              (key: Constant(value: key), value: value),
          ];

          values.add(Dict(pairs: pairs));
        }

        return node.copyWith(
          value: visitNode<Expression>(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              if (values.isNotEmpty) Array(values: values),
            ],
          ),
        );
      }

      if (_inMacro && name == 'caller' || _macros.contains(name)) {
        var calling = visitNode<Calling>(node.calling, context);
        var arguments = calling.arguments;
        var keywords = calling.keywords;

        return node.copyWith(
          value: visitNode<Expression>(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              Array(values: arguments.toList()),
              Dict(
                pairs: <Pair>[
                  for (var (:key, :value) in keywords)
                    (key: Constant(value: key), value: value),
                ],
              ),
            ],
          ),
        );
      }
    }

    if (node.value case Attribute attribute) {
      if (attribute.value case Name name when _imports.contains(name.name)) {
        var calling = visitNode<Calling>(node.calling, context);
        var arguments = calling.arguments;
        var keywords = calling.keywords;

        return node.copyWith(
          value: visitNode<Expression>(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              Array(values: arguments.toList()),
              Dict(
                pairs: <Pair>[
                  for (var (:key, :value) in keywords)
                    (key: Constant(value: key), value: value),
                ],
              ),
            ],
          ),
        );
      }
    }

    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Calling visitCalling(Calling node, void context) {
    return node.copyWith(
      arguments: visitNodes<Expression>(node.arguments, context),
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: visitNode<Expression>(value, context)),
      ],
    );
  }

  @override
  Compare visitCompare(Compare node, void context) {
    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, value.accept(this, context) as Expression),
      ],
    );
  }

  @override
  Concat visitConcat(Concat node, void context) {
    return node.copyWith(values: visitNodes<Expression>(node.values, context));
  }

  @override
  Condition visitCondition(Condition node, void context) {
    return node.copyWith(
      test: visitNode<Expression>(node.test, context),
      trueValue: visitNode<Expression>(node.trueValue, context),
      falseValue: visitNode<Expression?>(node.falseValue, context),
    );
  }

  @override
  Constant visitConstant(Constant node, void context) {
    return node;
  }

  @override
  Dict visitDict(Dict node, void context) {
    return node.copyWith(
      pairs: <Pair>[
        for (var (:key, :value) in node.pairs)
          (
            key: visitNode<Expression>(key, context),
            value: visitNode<Expression>(value, context),
          ),
      ],
    );
  }

  @override
  Filter visitFilter(Filter node, void context) {
    // Modifies Template AST from `map('filter', key=value)`
    // to `map(values, ['filter'], {'key': value})` to match [doMap] definition.
    if (node.name == 'map') {
      var calling = node.calling;

      calling = Calling(
        arguments: <Expression>[
          calling.arguments.first,
          Array(values: calling.arguments.sublist(1)),
          Dict(
            pairs: <Pair>[
              for (var (:key, :value) in calling.keywords)
                (key: Constant(value: key), value: value),
            ],
          ),
        ],
      );

      return node.copyWith(calling: visitNode<Calling>(calling, context));
    }

    return node.copyWith(calling: visitNode<Calling>(node.calling, context));
  }

  @override
  Item visitItem(Item node, void context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Logical visitLogical(Logical node, void context) {
    return node.copyWith(
      left: visitNode<Expression>(node.left, context),
      right: visitNode<Expression>(node.right, context),
    );
  }

  @override
  Name visitName(Name node, void context) {
    return node;
  }

  @override
  NamespaceRef visitNamespaceRef(NamespaceRef node, void context) {
    return node;
  }

  @override
  Scalar visitScalar(Scalar node, void context) {
    return node.copyWith(
      left: visitNode<Expression>(node.left, context),
      right: visitNode<Expression>(node.right, context),
    );
  }

  @override
  Node visitSlice(Slice node, void context) {
    return node.copyWith(
      start: visitNode<Expression?>(node.start, context),
      stop: visitNode<Expression?>(node.stop, context),
    );
  }

  @override
  Test visitTest(Test node, void context) {
    return node.copyWith(calling: visitNode<Calling>(node.calling, context));
  }

  @override
  Tuple visitTuple(Tuple node, void context) {
    return node.copyWith(values: visitNodes<Expression>(node.values, context));
  }

  @override
  Unary visitUnary(Unary node, void context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  // Statements

  @override
  Assign visitAssign(Assign node, void context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      value: visitNode<Expression>(node.value, context),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, void context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      filters: visitNodes<Filter>(node.filters, context),
      body: visitNodes<Node>(node.body, context),
    );
  }

  @override
  Block visitBlock(Block node, void context) {
    return node.copyWith(body: visitNodes<Node>(node.body, context));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, void context) {
    return node.copyWith(
      call: visitNode<Call>(node.call, context),
      positional: <Expression>[
        for (var argument in node.positional)
          argument.accept(this, context) as Expression,
      ],
      named: <(Expression, Expression)>[
        for (var (argument, defaultValue) in node.named)
          (
            argument.accept(this, context) as Expression,
            defaultValue.accept(this, context) as Expression,
          ),
      ],
      body: visitNodes<Node>(node.body, context),
    );
  }

  @override
  Data visitData(Data node, void context) {
    return node;
  }

  @override
  Do visitDo(Do node, void context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Extends visitExtends(Extends node, void context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, void context) {
    return node.copyWith(
      filters: visitNodes<Filter>(node.filters, context),
      body: visitNodes<Node>(node.body, context),
    );
  }

  @override
  For visitFor(For node, void context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      iterable: visitNode<Expression>(node.iterable, context),
      body: visitNodes<Node>(node.body, context),
      test: visitNode<Expression?>(node.test, context),
      orElse: visitNodes<Node>(node.orElse, context),
    );
  }

  @override
  FromImport visitFromImport(FromImport node, void context) {
    for (var (name, alias) in node.names) {
      _macros.add(alias ?? name);
    }

    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  If visitIf(If node, void context) {
    return node.copyWith(
      test: visitNode<Expression>(node.test, context),
      body: visitNodes<Node>(node.body, context),
      orElse: visitNodes<Node>(node.orElse, context),
    );
  }

  @override
  Import visitImport(Import node, void context) {
    _imports.add(node.target);
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Include visitInclude(Include node, void context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Interpolation visitInterpolation(Interpolation node, void context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Macro visitMacro(Macro node, void context) {
    _inMacro = true;
    _macros.add(node.name);

    var positional = <Expression>[];
    var named = <(Expression, Expression)>[];
    var explicitCaller = false;

    for (var argument in node.positional) {
      if (argument case Name(name: 'caller')) {
        throw TemplateAssertionError(
          'When defining macros or call blocks '
          'the special "caller" argument must be omitted or be given a '
          'default.',
        );
      }

      positional.add(argument.accept(this, context) as Expression);
    }

    for (var (argument, defaultValue) in node.named) {
      if (argument case Name(name: 'caller')) {
        explicitCaller = true;
      }

      named.add((
        argument.accept(this, context) as Expression,
        defaultValue.accept(this, context) as Expression,
      ));
    }

    if (node.caller && !explicitCaller) {
      named.add((Name.parameter(name: 'caller'), Constant(value: null)));
    }

    node = node.copyWith(
      positional: positional,
      named: named,
      body: visitNodes<Node>(node.body, context),
    );

    _inMacro = false;
    return node;
  }

  @override
  Node visitOutput(Output node, void context) {
    if (node.nodes.isEmpty) {
      return Data();
    }

    if (node.nodes.length == 1) {
      return visitNode<Node>(node.nodes[0], context);
    }

    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, void context) {
    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  Node visitTryCatch(TryCatch node, void context) {
    return node.copyWith(
      // TODO(compiler): skip bad nodes.
      body: visitNodes<Node>(node.body, context),
      exception: visitNode<Expression?>(node.exception, context),
      catchBody: visitNodes<Node>(node.catchBody, context),
    );
  }

  @override
  With visitWith(With node, void context) {
    return node.copyWith(
      targets: visitNodes<Expression>(node.targets, context),
      values: visitNodes<Expression>(node.values, context),
      body: visitNodes<Node>(node.body, context),
    );
  }
}
