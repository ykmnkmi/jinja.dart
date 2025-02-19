import 'dart:math' as math;

import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/runtime.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  T visitNode<T extends Node?>(Node? node, Context context) {
    return node?.accept(this, context) as T;
  }

  List<T> visitNodes<T extends Node>(List<Node> nodes, Context context) {
    T generate(int i) {
      return visitNode<T>(nodes[i], context);
    }

    return List<T>.generate(nodes.length, generate);
  }

  // Expressions

  @override
  Expression visitArray(Array node, Context context) {
    var values = visitNodes<Expression>(node.values, context);

    if (values.every((value) => value is Constant)) {
      return Constant(
        value: <Object?>[
          for (var value in values.cast<Constant>()) value.value,
        ],
      );
    }

    return node.copyWith(values: values);
  }

  @override
  Expression visitAttribute(Attribute node, Context context) {
    var value = visitNode<Expression>(node.value, context);

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
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Calling visitCalling(Calling node, Context context) {
    return node.copyWith(
      arguments: visitNodes<Expression>(node.arguments, context),
      keywords: <Keyword>[
        for (var (:key, :value) in node.keywords)
          (key: key, value: visitNode<Expression>(value, context))
      ],
    );
  }

  @override
  Expression visitCompare(Compare node, Context context) {
    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
      operands: <Operand>[
        for (var (operator, value) in node.operands)
          (operator, visitNode<Expression>(value, context)),
      ],
    );
  }

  @override
  Expression visitConcat(Concat node, Context context) {
    var values = visitNodes<Expression>(node.values, context);

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
    var test = visitNode<Expression>(node.test, context);
    var trueValue = visitNode<Expression>(node.trueValue, context);
    var falseValue = visitNode<Expression?>(node.falseValue, context);

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
          key: visitNode<Expression>(key, context),
          value: visitNode<Expression>(value, context),
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
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Expression visitItem(Item node, Context context) {
    var key = node.key;
    var value = node.value;

    if (key is Constant && value is Constant) {
      return Constant(value: context.item(key.value, value.value));
    }

    return node.copyWith(key: key, value: value);
  }

  @override
  Expression visitLogical(Logical node, Context context) {
    var left = visitNode<Expression>(node.left, context);
    var right = visitNode<Expression>(node.right, context);

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
    var left = visitNode<Expression>(node.left, context);
    var right = visitNode<Expression>(node.right, context);

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
    return node.copyWith(
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Expression visitTuple(Tuple node, Context context) {
    var values = visitNodes<Expression>(node.values, context);

    if (values.every((value) => value is Constant)) {
      return Constant(
        value: <Object?>[
          for (var value in values.cast<Constant>()) value.value,
        ],
      );
    }

    return node.copyWith(values: values);
  }

  @override
  Expression visitUnary(Unary node, Context context) {
    var value = visitNode<Expression>(node.value, context);

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
      target: visitNode<Expression>(node.target, context),
      value: visitNode<Expression>(node.value, context),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      filters: visitNodes<Filter>(node.filters, context),
      body: visitNode<Node>(node.body, context),
    );
  }

  @override
  Block visitBlock(Block node, Context context) {
    return node.copyWith(body: visitNode<Node>(node.body, context));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Context context) {
    return node.copyWith(
      call: visitNode<Call>(node.call, context),
      positional: visitNodes<Expression>(node.positional, context),
      named: <(Expression, Expression)>[
        for (var (argument, defaultValue) in node.named)
          (
            visitNode<Expression>(argument, context),
            visitNode<Expression>(defaultValue, context),
          )
      ],
      body: visitNode<Node>(node.body, context),
    );
  }

  @override
  Data visitData(Data node, Context context) {
    return node;
  }

  @override
  Do visitDo(Do node, Context context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Extends visitExtends(Extends node, Context context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Context context) {
    return node.copyWith(
      filters: visitNodes<Filter>(node.filters, context),
      body: visitNode<Node>(node.body, context),
    );
  }

  // TODO(optimizer): check false test
  @override
  For visitFor(For node, Context context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      iterable: visitNode<Expression>(node.iterable, context),
      body: visitNode<Node>(node.body, context),
      test: visitNode<Expression?>(node.test, context),
      orElse: visitNode<Node?>(node.orElse, context),
    );
  }

  @override
  FromImport visitFromImport(FromImport node, Context context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  If visitIf(If node, Context context) {
    return node.copyWith(
      test: visitNode<Expression>(node.test, context),
      body: visitNode<Node>(node.body, context),
      orElse: visitNode<Node?>(node.orElse, context),
    );
  }

  @override
  Import visitImport(Import node, Context context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Node visitInterpolation(Interpolation node, Context context) {
    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
    );
  }

  @override
  Macro visitMacro(Macro node, Context context) {
    return node.copyWith(
      positional: visitNodes<Expression>(node.positional, context),
      named: <(Expression, Expression)>[
        for (var (argument, defaultValue) in node.named)
          (
            visitNode<Expression>(argument, context),
            visitNode<Expression>(defaultValue, context),
          )
      ],
      body: visitNode<Node>(node.body, context),
    );
  }

  @override
  Node visitOutput(Output node, Context context) {
    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, Context context) {
    return node.copyWith(body: visitNode<Node>(node.body, context));
  }

  @override
  Node visitWith(With node, Context context) {
    return node.copyWith(
      targets: visitNodes<Expression>(node.targets, context),
      values: visitNodes<Expression>(node.values, context),
      body: visitNode<Node>(node.body, context),
    );
  }

  @override
  Node visitSlice(Slice node, Context context) {
    return node.copyWith(
      start: visitNode<Expression?>(node.start, context),
      stop: visitNode<Expression?>(node.stop, context),
    );
  }
}
