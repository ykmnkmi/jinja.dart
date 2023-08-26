import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  // Expressions

  @override
  Expression visitArray(Array node, Context context) {
    var values = <Expression>[
      for (var value in node.values) value.accept(this, context) as Expression
    ];

    if (values.every((value) => value is Constant)) {
      return Constant(
        value: <Object?>[
          for (var value in values.cast<Constant>()) value.value
        ],
      );
    }

    return node.copyWith(values: values);
  }

  @override
  Expression visitAttribute(Attribute node, Context context) {
    var value = node.value.accept(this, context) as Expression;

    if (value case Constant constant) {
      return Constant(
        value: context.attribute(node.attribute, constant.value),
      );
    }

    return node.copyWith(value: value);
  }

  @override
  Call visitCall(Call node, Context context) {
    return node.copyWith(
      calling: node.calling.accept(this, context) as Calling,
    );
  }

  @override
  Calling visitCalling(Calling node, Context context) {
    return node.copyWith(
      arguments: <Expression>[
        for (var argument in node.arguments)
          argument.accept(this, context) as Expression
      ],
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (
            key: key,
            value: value.accept(this, context) as Expression,
          )
      ],
    );
  }

  @override
  Expression visitCompare(Compare node, Context context) {
    return node.copyWith(
      value: node.value.accept(this, context) as Expression,
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, value.accept(this, context) as Expression)
      ],
    );
  }

  @override
  Expression visitConcat(Concat node, Context context) {
    var values = <Expression>[
      for (var value in node.values) value.accept(this, context) as Expression
    ];

    if (values.every((value) => value is Constant)) {
      return Constant(
        value: values
            .cast<Constant>()
            .map<Object?>((constant) => constant.value)
            .join(),
      );
    }

    var newValues = <Expression>[];
    var pack = <Object?>[];

    for (var value in values) {
      if (value case Constant constant) {
        pack.add(constant.value);
      } else {
        newValues
          ..add(Constant(value: pack.join()))
          ..add(value);

        pack.clear();
      }
    }

    if (pack.isNotEmpty) {
      newValues.add(Constant(value: pack.join()));
    }

    return node.copyWith(values: newValues);
  }

  @override
  Expression visitCondition(Condition node, Context context) {
    var test = node.test.accept(this, context) as Expression;
    var trueValue = node.trueValue.accept(this, context) as Expression;
    var falseValue = node.falseValue?.accept(this, context) as Expression?;

    if (test case Constant constant) {
      if (boolean(constant.value)) {
        return trueValue;
      } else {
        return falseValue ?? const Constant(value: null);
      }
    }

    return node.copyWith(
      test: test,
      trueValue: trueValue,
      falseValue: falseValue,
    );
  }

  @override
  Constant visitConstant(Constant node, Context context) {
    return node;
  }

  @override
  Expression visitDict(Dict node, Context context) {
    var pairs = <Pair>[
      for (var (:key, :value) in node.pairs)
        (
          key: key.accept(this, context) as Expression,
          value: value.accept(this, context) as Expression,
        )
    ];

    if (pairs.any((pair) => pair.key is Constant && pair.value is Constant)) {
      var constantPairs = pairs.cast<({Constant key, Constant value})>();

      return Constant(
        value: <Object?, Object?>{
          for (var (:key, :value) in constantPairs) key.value: value.value,
        },
      );
    }

    return node.copyWith(pairs: pairs);
  }

  @override
  Filter visitFilter(Filter node, Context context) {
    return node.copyWith(
      calling: node.calling.accept(this, context) as Calling,
    );
  }

  @override
  Expression visitItem(Item node, Context context) {
    var key = node.key;
    var value = node.value;

    if (key is Constant && value is Constant) {
      return Constant(value: context.item(key.value!, value.value));
    }

    return node.copyWith(key: key, value: value);
  }

  @override
  Expression visitLogical(Logical node, Context context) {
    var left = node.left.accept(this, context) as Expression;
    var right = node.right.accept(this, context) as Expression;

    if (left case Constant constant) {
      return switch (node.operator) {
        LogicalOperator.and => boolean(constant.value) ? right : constant,
        LogicalOperator.or => boolean(constant.value) ? constant : right,
      };
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Name visitName(Name node, Context context) {
    return node;
  }

  @override
  NamespaceRef visitNamespaceRef(NamespaceRef node, Context context) {
    return node;
  }

  @override
  Expression visitScalar(Scalar node, Context context) {
    var left = node.left.accept(this, context) as Expression;
    var right = node.right.accept(this, context) as Expression;

    if (left is Constant && right is Constant) {
      return Constant(
        value: switch (node.operator) {
          ScalarOperator.power =>
            math.pow(left.value as num, right.value as num),
          // ignore: avoid_dynamic_calls
          ScalarOperator.module => (left.value as dynamic) % right.value,
          ScalarOperator.floorDivision =>
            // ignore: avoid_dynamic_calls
            (left.value as dynamic) ~/ right.value,
          // ignore: avoid_dynamic_calls
          ScalarOperator.division => (left.value as dynamic) / right.value,
          // ignore: avoid_dynamic_calls
          ScalarOperator.multiple => (left.value as dynamic) * right.value,
          // ignore: avoid_dynamic_calls
          ScalarOperator.minus => (left.value as dynamic) - right.value,
          // ignore: avoid_dynamic_calls
          ScalarOperator.plus => (left.value as dynamic) + right.value,
        },
      );
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Test visitTest(Test node, Context context) {
    var calling = node.calling.accept(this, context) as Calling;
    return node.copyWith(calling: calling);
  }

  @override
  Expression visitTuple(Tuple node, Context context) {
    var values = <Expression>[
      for (var value in node.values) value.accept(this, context) as Expression
    ];

    if (values.every((value) => value is Constant)) {
      return Constant(
        value: <Object?>[
          for (var value in values.cast<Constant>()) value.value
        ],
      );
    }

    return node.copyWith(values: values);
  }

  @override
  Expression visitUnary(Unary node, Context context) {
    var value = node.value.accept(this, context) as Expression;

    if (value case Constant constant) {
      return Constant(
        value: switch (node.operator) {
          UnaryOperator.plus => constant.value,
          // ignore: avoid_dynamic_calls
          UnaryOperator.minus => -(constant.value as dynamic),
          UnaryOperator.not => !boolean(constant.value),
        },
      );
    }

    return node.copyWith(value: value);
  }

  // Statements

  @override
  Assign visitAssign(Assign node, Context context) {
    return node.copyWith(
      target: node.target.accept(this, context) as Expression,
      value: node.value.accept(this, context) as Expression,
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    return node.copyWith(
      target: node.target.accept(this, context) as Expression,
      filters: <Filter>[
        for (var filter in node.filters) filter.accept(this, context) as Filter
      ],
      body: node.body.accept(this, context),
    );
  }

  @override
  Block visitBlock(Block node, Context context) {
    return node.copyWith(
      body: node.body.accept(this, context),
    );
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Context context) {
    return node.copyWith(
      call: node.call.accept(this, context) as Call,
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
      body: node.body.accept(this, context),
    );
  }

  @override
  Data visitData(Data node, Context context) {
    return node;
  }

  @override
  Do visitDo(Do node, Context context) {
    return node.copyWith(
      value: node.value.accept(this, context) as Expression,
    );
  }

  @override
  Extends visitExtends(Extends node, Context context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Context context) {
    return node.copyWith(
      filters: <Filter>[
        for (var filter in node.filters) filter.accept(this, context) as Filter
      ],
      body: node.body.accept(this, context),
    );
  }

  // TODO(optimizer): check false test
  @override
  For visitFor(For node, Context context) {
    return node.copyWith(
      target: node.target.accept(this, context) as Expression,
      iterable: node.iterable.accept(this, context) as Expression,
      body: node.body.accept(this, context),
      test: node.test?.accept(this, context) as Expression?,
      orElse: node.orElse?.accept(this, context),
    );
  }

  @override
  If visitIf(If node, Context context) {
    return node.copyWith(
      test: node.test.accept(this, context) as Expression,
      body: node.body.accept(this, context),
      orElse: node.orElse?.accept(this, context),
    );
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node;
  }

  @override
  Node visitInterpolation(Interpolation node, Context context) {
    return node.copyWith(
      value: node.value.accept(this, context) as Expression,
    );
  }

  @override
  Macro visitMacro(Macro node, Context context) {
    return node.copyWith(
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
      body: node.body.accept(this, context),
    );
  }

  @override
  Node visitOutput(Output node, Context context) {
    return node.copyWith(
      nodes: <Node>[for (var node in node.nodes) node.accept(this, context)],
    );
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, Context context) {
    return node.copyWith(
      blocks: <Block>[
        for (var block in node.blocks) block.accept(this, context) as Block
      ],
      body: node.body.accept(this, context),
    );
  }

  @override
  Node visitWith(With node, Context context) {
    return node.copyWith(
      targets: <Expression>[
        for (var target in node.targets)
          target.accept(this, context) as Expression
      ],
      values: <Expression>[
        for (var value in node.values) value.accept(this, context) as Expression
      ],
      body: node.body.accept(this, context),
    );
  }
}
