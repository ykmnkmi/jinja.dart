import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class RuntimeCompiler implements Visitor<void, Node> {
  const RuntimeCompiler();

  T visitNode<T extends Node?>(Node? node) {
    return node?.accept(this, null) as T;
  }

  List<T> visitNodes<T extends Node>(List<Node> nodes) {
    return <T>[for (var node in nodes) visitNode(node)];
  }

  // Expressions

  @override
  Array visitArray(Array node, void _) {
    return node.copyWith(values: visitNodes(node.values));
  }

  @override
  Node visitAttribute(Attribute node, void _) {
    // Modifies Template AST from `self.block()` to `self['block']()`.
    if (node.value case Name(name: 'self')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode(node.value),
      );
    }

    // Modifies Template AST from `loop.cycle` to `loop['cycle']`.

    if (node.value case Name(name: 'loop')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode(node.value),
      );
    }

    return node.copyWith(value: visitNode(node.value));
  }

  @override
  Call visitCall(Call node, void _) {
    // TODO(compiler): handle super call
    switch (node.value) {
      // Modifies Template AST from `loop.cycle(first, second, *list)`
      // to `loop['cycle']([first, second], list)`, which matches
      // [LoopContext.cycle] definition.
      //
      // TODO(compiler): check name arguments
      case Attribute(attribute: 'cycle', value: Name(name: 'loop')):
        var calling = node.calling;

        var arguments = <Expression>[Array(values: calling.arguments)];

        if (calling.dArguments case var dArguments?) {
          arguments.add(dArguments);
        }

        return node.copyWith(
          value: visitNode(node.value),
          calling: Calling(arguments: visitNodes(arguments)),
        );

      // Modifies Template AST from `namespace(map1, ..., key1=value1, ...)`
      // to `namespace([map1, ..., {'key1': value1, ...}])`, to match [namespace]
      // definition.
      case Name(name: 'namespace'):
        var values = node.calling.arguments.toList();

        if (node.calling.keywords.isNotEmpty) {
          var pairs = <Pair>[
            for (var (:key, :value) in node.calling.keywords)
              (key: Constant(value: key), value: value)
          ];

          values.add(Dict(pairs: pairs));
        }

        if (node.calling.dArguments case var dArguments?) {
          values.add(dArguments);
        }

        if (node.calling.dKeywords case var dKeywords?) {
          values.add(dKeywords);
        }

        return node.copyWith(
          value: visitNode(node.value),
          calling: Calling(
            arguments: <Expression>[
              if (values.isNotEmpty) Array(values: values)
            ],
          ),
        );

      default:
        return node.copyWith(
          value: visitNode(node.value),
          calling: visitNode(node.calling),
        );
    }
  }

  @override
  Callback visitCallback(Callback node, void _) {
    return node;
  }

  @override
  Calling visitCalling(Calling node, void _) {
    return node.copyWith(
      arguments: visitNodes(node.arguments),
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: visitNode(value))
      ],
      dArguments: visitNode(node.dArguments),
      dKeywords: visitNode(node.dKeywords),
    );
  }

  @override
  Compare visitCompare(Compare node, void _) {
    return node.copyWith(
      value: visitNode(node.value),
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, value.accept(this, null) as Expression)
      ],
    );
  }

  @override
  Concat visitConcat(Concat node, void _) {
    return node.copyWith(values: visitNodes(node.values));
  }

  @override
  Condition visitCondition(Condition node, void _) {
    return node.copyWith(
      test: visitNode(node.test),
      trueValue: visitNode(node.trueValue),
      falseValue: visitNode(node.falseValue),
    );
  }

  @override
  Constant visitConstant(Constant node, void _) {
    return node;
  }

  @override
  Dict visitDict(Dict node, void _) {
    return node.copyWith(
      pairs: <Pair>[
        for (var (:key, :value) in node.pairs)
          (key: visitNode(key), value: visitNode(value))
      ],
    );
  }

  @override
  Filter visitFilter(Filter node, void _) {
    // Modifies Template AST from `map('filter', *args, **kwargs)`
    // to `map(filter='filter', positional=args, named=kwargs)`
    // to match [doMap] definition.
    if (node.name == 'map') {
      var calling = node.calling;

      var arguments = <Expression>[calling.arguments.first];
      var keywords = <Keyword>[];

      var values = <Expression>[];
      var pairs = <Pair>[];

      if (calling.arguments.length > 1) {
        keywords.add((key: 'filter', value: calling.arguments[1]));
        values.addAll(calling.arguments.skip(2));
      }

      for (var (:key, :value) in calling.keywords) {
        switch (key) {
          case 'attribute' || 'item' || 'defaultValue':
            keywords.add((key: key, value: value));
            break;

          default:
            pairs.add((key: Constant(value: key), value: value));
        }
      }

      keywords
        ..add((key: 'positional', value: Array(values: values)))
        ..add((key: 'named', value: Dict(pairs: pairs)));

      return node.copyWith(
        calling: visitNode(Calling(arguments: arguments, keywords: keywords)),
      );
    }

    return node.copyWith(calling: visitNode(node.calling));
  }

  @override
  Item visitItem(Item node, void _) {
    return node.copyWith(value: visitNode(node.value));
  }

  @override
  Logical visitLogical(Logical node, void _) {
    return node.copyWith(
      left: visitNode(node.left),
      right: visitNode(node.right),
    );
  }

  @override
  Name visitName(Name node, void _) {
    return node;
  }

  @override
  NamespaceRef visitNamespaceRef(NamespaceRef node, void _) {
    return node;
  }

  @override
  Scalar visitScalar(Scalar node, void _) {
    return node.copyWith(
      left: visitNode(node.left),
      right: visitNode(node.right),
    );
  }

  @override
  Test visitTest(Test node, void _) {
    return node.copyWith(calling: visitNode(node.calling));
  }

  @override
  Tuple visitTuple(Tuple node, void _) {
    return node.copyWith(values: visitNodes(node.values));
  }

  @override
  Unary visitUnary(Unary node, void _) {
    return node.copyWith(value: visitNode(node.value));
  }

  // Statements

  @override
  Assign visitAssign(Assign node, void _) {
    return node.copyWith(
      target: visitNode(node.target),
      value: visitNode(node.value),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, void _) {
    return node.copyWith(
      target: visitNode(node.target),
      filters: visitNodes(node.filters),
      body: visitNode(node.body),
    );
  }

  @override
  AutoEscape visitAutoEscape(AutoEscape node, void _) {
    return node.copyWith(
      value: visitNode(node.value),
      body: visitNode(node.body),
    );
  }

  @override
  Block visitBlock(Block node, void _) {
    return node.copyWith(body: visitNode(node.body));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, void _) {
    return node.copyWith(
      call: visitNode(node.call),
      arguments: visitNodes(node.arguments),
      defaults: visitNodes(node.defaults),
      body: visitNode(node.body),
    );
  }

  @override
  Data visitData(Data node, void _) {
    return node;
  }

  @override
  Do visitDo(Do node, void _) {
    return node.copyWith(value: visitNode(node.value));
  }

  @override
  Extends visitExtends(Extends node, void _) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, void _) {
    return node.copyWith(
      filters: visitNodes(node.filters),
      body: visitNode(node.body),
    );
  }

  @override
  For visitFor(For node, void _) {
    return node.copyWith(
      target: visitNode(node.target),
      iterable: visitNode(node.iterable),
      body: visitNode(node.body),
      test: visitNode(node.test),
      orElse: visitNode(node.orElse),
    );
  }

  @override
  If visitIf(If node, void _) {
    return node.copyWith(
      test: visitNode(node.test),
      body: visitNode(node.body),
    );
  }

  @override
  Include visitInclude(Include node, void _) {
    return node;
  }

  @override
  Interpolation visitInterpolation(Interpolation node, void _) {
    return node.copyWith(value: visitNode(node.value));
  }

  @override
  Macro visitMacro(Macro node, void _) {
    return node.copyWith(
      arguments: visitNodes(node.arguments),
      defaults: visitNodes(node.defaults),
      body: visitNode(node.body),
    );
  }

  @override
  Output visitOutput(Output node, void _) {
    return node.copyWith(nodes: visitNodes(node.nodes));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, void _) {
    return node.copyWith(
      // blocks: visitNodes(node.blocks),
      body: visitNode(node.body),
    );
  }

  @override
  With visitWith(With node, void _) {
    return node.copyWith(
      targets: visitNodes(node.targets),
      values: visitNodes(node.values),
      body: visitNode(node.body),
    );
  }
}
