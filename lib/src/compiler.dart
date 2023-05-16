import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

class RuntimeCompiler<C extends Object?> implements Visitor<C, Node> {
  const RuntimeCompiler();

  // Expressions

  @override
  Array visitArray(Array node, C context) {
    return node.copyWith(
      values: <Expression>[
        for (var value in node.values) value.accept(this, context) as Expression
      ],
    );
  }

  @override
  Node visitAttribute(Attribute node, C context) {
    // Modifies Template AST from `self.block()` to `self['block']()`.
    if (node.value case Name(name: 'self')) {
      return Item(key: Constant(value: node.attribute), value: node.value);
    }

    // Modifies Template AST from `loop.cycle` to `loop['cycle']`.

    if (node.value case Name(name: 'loop')) {
      return Item(key: Constant(value: node.attribute), value: node.value);
    }

    return node.copyWith(value: node.value.accept(this, context) as Expression);
  }

  @override
  Call visitCall(Call node, C context) {
    const loopCycle = Attribute(attribute: 'cycle', value: Name(name: 'loop'));

    // Modifies Template AST from `loop.cycle(first, second, *list)`
    // to `loop['cycle']([first, second], list)`, which matches
    // [LoopContext.cycle] definition.
    //
    // TODO(compiler): check name arguments
    if (node case Call(value: loopCycle, calling: var calling)) {
      var arguments = <Expression>[Array(values: calling.arguments)];

      if (calling.dArguments case var dArguments?) {
        arguments.add(dArguments);
      }

      return node.copyWith(
        value: node.value.accept(this, context) as Expression,
        // calling: calling.copyWith(
        //   arguments: arguments,
        //   keywords: const <Keyword>[],
        //   dArguments: null,
        //   dKeywords: null,
        // ),
        calling: Calling(arguments: arguments),
      );
    }

    // Modifies Template AST from `namespace(map1, ..., key1=value1, ...)`
    // to `namespace([map1, ..., {'key1': value1, ...}])`, to match [namespace]
    // definition.
    if (node.value case Name(name: 'namespace')) {
      var calling = node.calling;

      var arguments = <Expression>[
        for (var argument in calling.arguments)
          argument.accept(this, context) as Expression
      ];

      if (calling.keywords.isNotEmpty) {
        var pairs = <Pair>[
          for (var (:key, :value) in calling.keywords)
            (
              key: Constant(value: key),
              value: value.accept(this, context) as Expression
            )
        ];

        arguments.add(Dict(pairs: pairs));
      }

      if (calling.dArguments case var dArguments?) {
        arguments.add(dArguments.accept(this, context) as Expression);
      }

      if (calling.dKeywords case var dKeywords?) {
        arguments.add(dKeywords.accept(this, context) as Expression);
      }

      return node.copyWith(
        value: node.value.accept(this, context) as Expression,
        // calling: calling.copyWith(
        //   arguments: arguments,
        //   keywords: <Keyword>[],
        //   dArguments: null,
        //   dKeywords: null,
        // ),
        calling: Calling(arguments: arguments, keywords: <Keyword>[]),
      );
    }

    return node.copyWith(
      value: node.value.accept(this, context) as Expression,
      calling: node.calling.accept(this, context) as Calling,
    );
  }

  @override
  Calling visitCalling(Calling node, C context) {
    return node.copyWith(
      arguments: <Expression>[
        for (var argument in node.arguments)
          argument.accept(this, context) as Expression
      ],
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: value.accept(this, context) as Expression)
      ],
      dArguments: node.dArguments?.accept(this, context) as Expression?,
      dKeywords: node.dKeywords?.accept(this, context) as Expression?,
    );
  }

  @override
  Compare visitCompare(Compare node, C context) {
    return node.copyWith(
      left: node.left.accept(this, context) as Expression,
      right: node.right.accept(this, context) as Expression,
    );
  }

  @override
  Concat visitConcat(Concat node, C context) {
    return node.copyWith(
      values: <Expression>[
        for (var value in node.values) value.accept(this, context) as Expression
      ],
    );
  }

  @override
  Condition visitCondition(Condition node, C context) {
    return node;
  }

  @override
  Constant visitConstant(Constant node, C context) {
    return node;
  }

  @override
  Dict visitDict(Dict node, C context) {
    return node;
  }

  @override
  Filter visitFilter(Filter node, C context) {
    // Modifies Template AST from `map('filter', *args, **kwargs)`
    // to `map(filter='filter', positional=args, named=kwargs)`
    // to match [doMap] definition.
    if (node.name == 'map') {
      var calling = node.calling;

      var arguments = <Expression>[
        calling.arguments[0].accept(this, context) as Expression,
      ];

      var keywords = <Keyword>[];

      var values = <Expression>[];
      var pairs = <Pair>[];

      if (calling.arguments.length > 1) {
        keywords.add((
          key: 'filter',
          value: calling.arguments[1].accept(this, context) as Expression,
        ));

        values.addAll([
          for (var argument in calling.arguments.skip(2))
            argument.accept(this, context) as Expression
        ]);
      }

      for (var (:key, :value) in calling.keywords) {
        switch (key) {
          case 'attribute' || 'item' || 'defaultValue':
            keywords.add((
              key: key,
              value: value.accept(this, context) as Expression,
            ));

            break;

          default:
            pairs.add((
              key: Constant(value: key),
              value: value.accept(this, context) as Expression,
            ));
        }
      }

      keywords
        ..add((key: 'positional', value: Array(values: values)))
        ..add((key: 'named', value: Dict(pairs: pairs)));

      calling = calling.copyWith(arguments: arguments, keywords: keywords);
      node = node.copyWith(calling: calling);
    }

    return node;
  }

  @override
  Item visitItem(Item node, C context) {
    return node;
  }

  @override
  Logical visitLogical(Logical node, C context) {
    return node;
  }

  @override
  Name visitName(Name node, C context) {
    return node;
  }

  @override
  NamespaceRef visitNamespaceRef(NamespaceRef node, C context) {
    return node;
  }

  @override
  Scalar visitScalar(Scalar node, C context) {
    return node;
  }

  @override
  Test visitTest(Test node, C context) {
    return node;
  }

  @override
  Tuple visitTuple(Tuple node, C context) {
    return node;
  }

  @override
  Unary visitUnary(Unary node, C context) {
    return node;
  }

  // Statements

  @override
  Assign visitAssign(Assign node, C context) {
    return node;
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, C context) {
    return node;
  }

  @override
  AutoEscape visitAutoEscape(AutoEscape node, C context) {
    return node;
  }

  @override
  Block visitBlock(Block node, C context) {
    return node;
  }

  @override
  CallBlock visitCallBlock(CallBlock node, C context) {
    return node;
  }

  @override
  Data visitData(Data node, C context) {
    return node;
  }

  @override
  Do visitDo(Do node, C context) {
    return node;
  }

  @override
  Extends visitExtends(Extends node, C context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, C context) {
    return node;
  }

  @override
  For visitFor(For node, C context) {
    return node;
  }

  @override
  If visitIf(If node, C context) {
    return node;
  }

  @override
  Include visitInclude(Include node, C context) {
    return node;
  }

  @override
  Interpolation visitInterpolation(Interpolation node, C context) {
    return node;
  }

  @override
  Macro visitMacro(Macro node, C context) {
    return node;
  }

  @override
  Output visitOutput(Output node, C context) {
    return node;
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, C context) {
    return node;
  }

  @override
  With visitWith(With node, C context) {
    return node;
  }
}
