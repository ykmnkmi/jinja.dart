import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class RuntimeCompiler implements Visitor<void, Node> {
  RuntimeCompiler()
      : _imports = <String>{},
        _macroses = <String>{},
        _inMacro = false;

  final Set<String> _imports;

  final Set<String> _macroses;

  bool _inMacro;

  T visitNode<T extends Node?>(Node? node, void context) {
    return node?.accept(this, context) as T;
  }

  List<T> visitNodes<T extends Node>(List<Node> nodes, void context) {
    return <T>[for (var node in nodes) visitNode(node, context)];
  }

  // Expressions

  @override
  Array visitArray(Array node, void context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Node visitAttribute(Attribute node, void context) {
    // Modifies Template AST from `object.prop` to `object['prop']`.
    if (node.value case Name(name: 'self' || 'loop')) {
      return Item(
        key: Constant(value: node.attribute),
        value: visitNode(node.value, context),
      );
    }

    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Call visitCall(Call node, void context) {
    // Modifies Template AST from `loop.cycle(first, second, *list)`
    // to `loop['cycle']([first, second], list)`, which matches
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
        var calling = visitNode<Calling>(node.calling, context);
        var values = calling.arguments.toList();

        if (calling.keywords.isNotEmpty) {
          var pairs = <Pair>[
            for (var (:key, :value) in calling.keywords)
              (key: Constant(value: key), value: value)
          ];

          values.add(Dict(pairs: pairs));
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

      if (_macroses.contains(name) || _inMacro && name == 'caller') {
        var calling = visitNode<Calling>(node.calling, context);
        var arguments = calling.arguments;
        var keywords = calling.keywords;

        return node.copyWith(
          value: visitNode(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              Array(values: arguments.toList()),
              Dict(pairs: <Pair>[
                for (var (:key, :value) in keywords)
                  (key: Constant(value: key), value: value),
              ]),
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
          value: visitNode(node.value, context),
          calling: Calling(
            arguments: <Expression>[
              Array(values: arguments.toList()),
              Dict(pairs: <Pair>[
                for (var (:key, :value) in keywords)
                  (key: Constant(value: key), value: value),
              ]),
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
  Calling visitCalling(Calling node, void context) {
    return node.copyWith(
      arguments: visitNodes(node.arguments, context),
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: visitNode(value, context))
      ],
    );
  }

  @override
  Compare visitCompare(Compare node, void context) {
    return node.copyWith(
      value: visitNode(node.value, context),
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, value.accept(this, context) as Expression)
      ],
    );
  }

  @override
  Concat visitConcat(Concat node, void context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Condition visitCondition(Condition node, void context) {
    return node.copyWith(
      test: visitNode(node.test, context),
      trueValue: visitNode(node.trueValue, context),
      falseValue: visitNode(node.falseValue, context),
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
          (key: visitNode(key, context), value: visitNode(value, context))
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
  Item visitItem(Item node, void context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Logical visitLogical(Logical node, void context) {
    return node.copyWith(
      left: visitNode(node.left, context),
      right: visitNode(node.right, context),
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
      left: visitNode(node.left, context),
      right: visitNode(node.right, context),
    );
  }

  @override
  Test visitTest(Test node, void context) {
    return node.copyWith(calling: visitNode(node.calling, context));
  }

  @override
  Tuple visitTuple(Tuple node, void context) {
    return node.copyWith(values: visitNodes(node.values, context));
  }

  @override
  Unary visitUnary(Unary node, void context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  // Statements

  @override
  Assign visitAssign(Assign node, void context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      value: visitNode(node.value, context),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, void context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      filters: visitNodes(node.filters, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  Block visitBlock(Block node, void context) {
    return node.copyWith(body: visitNode(node.body, context));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, void context) {
    return node.copyWith(
      call: visitNode(node.call, context),
      positional: <Expression>[
        for (var argument in node.positional)
          argument.accept(this, context) as Expression,
      ],
      named: <(Expression, Expression)>[
        for (var (argument, defaultValue) in node.named)
          (
            argument.accept(this, context) as Expression,
            defaultValue.accept(this, context) as Expression,
          )
      ],
      body: visitNode(node.body, context),
    );
  }

  @override
  Data visitData(Data node, void context) {
    return node;
  }

  @override
  Do visitDo(Do node, void context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Extends visitExtends(Extends node, void context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, void context) {
    return node.copyWith(
      filters: visitNodes(node.filters, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  For visitFor(For node, void context) {
    return node.copyWith(
      target: visitNode(node.target, context),
      iterable: visitNode(node.iterable, context),
      body: visitNode(node.body, context),
      test: visitNode(node.test, context),
      orElse: visitNode(node.orElse, context),
    );
  }

  @override
  If visitIf(If node, void context) {
    return node.copyWith(
      test: visitNode(node.test, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  Import visitImport(Import node, void context) {
    _imports.add(node.target);
    return node;
  }

  @override
  Include visitInclude(Include node, void context) {
    return node;
  }

  @override
  Interpolation visitInterpolation(Interpolation node, void context) {
    return node.copyWith(value: visitNode(node.value, context));
  }

  @override
  Macro visitMacro(Macro node, void context) {
    _inMacro = true;
    _macroses.add(node.name);

    var positional = <Expression>[];
    var named = <(Expression, Expression)>[];
    var explicitCaller = false;

    for (var argument in node.positional) {
      if (argument case Name(name: 'caller')) {
        throw TemplateAssertionError('When defining macros or call blocks '
            'the special "caller" argument must be omitted or be given a '
            'default.');
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
      body: visitNode(node.body, context),
    );

    _inMacro = false;
    return node;
  }

  @override
  Output visitOutput(Output node, void context) {
    return node.copyWith(nodes: visitNodes(node.nodes, context));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, void context) {
    return node.copyWith(
      blocks: visitNodes(node.blocks, context),
      body: visitNode(node.body, context),
    );
  }

  @override
  With visitWith(With node, void context) {
    return node.copyWith(
      targets: visitNodes(node.targets, context),
      values: visitNodes(node.values, context),
      body: visitNode(node.body, context),
    );
  }
}
