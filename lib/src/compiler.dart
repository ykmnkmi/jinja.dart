import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class RuntimeCompiler implements Visitor<Set<String>, Node> {
  const RuntimeCompiler();

  T visitNode<T extends Node?>(Node? node, Set<String> context) {
    return node?.accept(this, context) as T;
  }

  List<T> visitNodes<T extends Node>(List<Node> nodes, Set<String> context) {
    return <T>[for (var node in nodes) visitNode(node, context)];
  }

  // Expressions

  @override
  Array visitArray(Array node, Set<String> context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Node visitAttribute(Attribute node, Set<String> context) {
    // Modifies Template AST from `self.block()` to `self['block']()`.
    if (node.value case Name(name: 'self')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode(node.value, context),
      );
    }

    // Modifies Template AST from `loop.cycle` to `loop['cycle']`.

    if (node.value case Name(name: 'loop')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode(node.value, context),
      );
    }

    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Call visitCall(Call node, Set<String> context) {
    // Modifies Template AST from `loop.cycle(first, second, *list)`
    // to `loop['cycle']([first, second], list)`, which matches
    // [LoopContext.cycle] definition.
    //
    // TODO(compiler): check name arguments
    if (node.value case Attribute(attribute: 'cycle', value: var value)) {
      if (value case Name(name: 'loop')) {
        var calling = node.calling;

        var arguments = <Expression>[Array(values: calling.arguments)];

        if (calling.dArguments case var dArguments?) {
          arguments.add(dArguments);
        }

        return node.copyWith(
          value: visitNode(node.value, context),
          calling: Calling(arguments: visitNodes(arguments, context)),
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
          value: visitNode(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              if (values.isNotEmpty) Array(values: values)
            ],
          ),
        );
      }

      // Is it a macro call?
      // TODO(compiler): need to handle named arguments too.
      if (context.contains(name)) {
        var values = node.calling.arguments.toList();

        if (node.calling.dArguments case var dArguments?) {
          values.add(dArguments);
        }

        return node.copyWith(
          value: visitNode(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              Array(values: values),
              const Constant(value: <Object?, Object?>{}),
            ],
          ),
        );
      }
    }

    return node.copyWith(
      value: visitNode(node.value, context),
      calling: visitNode(node.calling, context),
    );
  }

  @override
  Calling visitCalling(Calling node, Set<String> context) {
    return node.copyWith(
      arguments: visitNodes(node.arguments, context),
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: visitNode(value, context))
      ],
      dArguments: visitNode(node.dArguments, context),
      dKeywords: visitNode(node.dKeywords, context),
    );
  }

  @override
  Compare visitCompare(Compare node, Set<String> context) {
    return node.copyWith(
      value: visitNode(node.value, context),
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, value.accept(this, context) as Expression)
      ],
    );
  }

  @override
  Concat visitConcat(Concat node, Set<String> context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Condition visitCondition(Condition node, Set<String> context) {
    return node.copyWith(
      test: visitNode(node.test, context),
      trueValue: visitNode(node.trueValue, context),
      falseValue: visitNode(node.falseValue, context),
    );
  }

  @override
  Constant visitConstant(Constant node, Set<String> context) {
    return node;
  }

  @override
  Dict visitDict(Dict node, Set<String> context) {
    return node.copyWith(
      pairs: <Pair>[
        for (var (:key, :value) in node.pairs)
          (key: visitNode(key, context), value: visitNode(value, context))
      ],
    );
  }

  @override
  Filter visitFilter(Filter node, Set<String> context) {
    // Modifies Template AST from `map('filter', *args, **kwargs)`
    // to `map(filter='filter', positional=args, named=kwargs)`
    // to match [doMap] definition.
    if (node.name == 'map') {
      var calling = node.calling;

      calling = Calling(
        arguments: <Expression>[
          calling.arguments.first,
          Array(values: calling.arguments.sublist(1)),
          Dict(pairs: <Pair>[
            for (var (:key, :value) in calling.keywords)
              (key: Constant(value: key), value: value)
          ]),
        ],
      );

      return node.copyWith(
        calling: visitNode(calling, context),
      );
    }

    return node.copyWith(calling: visitNode(node.calling, context));
  }

  @override
  Item visitItem(Item node, Set<String> context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Logical visitLogical(Logical node, Set<String> context) {
    return node.copyWith(
      left: visitNode(node.left, context),
      right: visitNode(node.right, context),
    );
  }

  @override
  Name visitName(Name node, Set<String> context) {
    return node;
  }

  @override
  NamespaceRef visitNamespaceRef(NamespaceRef node, Set<String> context) {
    return node;
  }

  @override
  Scalar visitScalar(Scalar node, Set<String> context) {
    return node.copyWith(
      left: visitNode(node.left, context),
      right: visitNode(node.right, context),
    );
  }

  @override
  Test visitTest(Test node, Set<String> context) {
    return node.copyWith(calling: visitNode(node.calling, context));
  }

  @override
  Tuple visitTuple(Tuple node, Set<String> context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Unary visitUnary(Unary node, Set<String> context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  // Statements

  @override
  Assign visitAssign(Assign node, Set<String> context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      value: visitNode(node.value, context),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Set<String> context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      filters: visitNodes(node.filters, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  AutoEscape visitAutoEscape(AutoEscape node, Set<String> context) {
    return node.copyWith(
      value: visitNode(node.value, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  Block visitBlock(Block node, Set<String> context) {
    return node.copyWith(body: visitNode(node.body, context));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Set<String> context) {
    return node.copyWith(
      call: visitNode(node.call, context),
      arguments: <(Expression, Expression?)>[
        for (var (argument, default_) in node.arguments)
          (
            argument.accept(this, context) as Expression,
            default_?.accept(this, context) as Expression?
          )
      ],
      body: visitNode(node.body, context),
    );
  }

  @override
  Data visitData(Data node, Set<String> context) {
    return node;
  }

  @override
  Do visitDo(Do node, Set<String> context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Extends visitExtends(Extends node, Set<String> context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Set<String> context) {
    return node.copyWith(
      filters: visitNodes(node.filters, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  For visitFor(For node, Set<String> context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      iterable: visitNode(node.iterable, context),
      body: visitNode(node.body, context),
      test: visitNode(node.test, context),
      orElse: visitNode(node.orElse, context),
    );
  }

  @override
  If visitIf(If node, Set<String> context) {
    return node.copyWith(
      test: visitNode(node.test, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  Include visitInclude(Include node, Set<String> context) {
    return node;
  }

  @override
  Interpolation visitInterpolation(Interpolation node, Set<String> context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Macro visitMacro(Macro node, Set<String> context) {
    context.add(node.name);

    return node.copyWith(
      arguments: <(Expression, Expression?)>[
        for (var (argument, default_) in node.arguments)
          (
            argument.accept(this, context) as Expression,
            default_?.accept(this, context) as Expression?
          )
      ],
      body: visitNode(node.body, context),
    );
  }

  @override
  Output visitOutput(Output node, Set<String> context) {
    return node.copyWith(nodes: visitNodes(node.nodes, context));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, Set<String> context) {
    return node.copyWith(
      blocks: visitNodes(node.blocks, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  With visitWith(With node, Set<String> context) {
    return node.copyWith(
      targets: visitNodes(node.targets, context),
      values: visitNodes(node.values, context),
      body: visitNode(node.body, context),
    );
  }
}
