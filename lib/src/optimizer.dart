import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/tests.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';

class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  // Expressions

  Expression visitExpression(Expression node, Context context) {
    return node.accept(this, context) as Expression;
  }

  @override
  Node visitArray(Array node, Context context) {
    var values = <Expression>[
      for (var value in node.values) visitExpression(value, context)
    ];

    if (values.every((value) => value is Constant)) {
      var value = values
          .cast<Constant>()
          .map<Object?>((constant) => constant.value)
          .toList();

      return Constant(value: value);
    }

    return node.copyWith(values: values);
  }

  @override
  Node visitAttribute(Attribute node, Context context) {
    var value = visitExpression(node.value, context);

    if (value is Constant) {
      var valueAttribute = context.attribute(value, node.attribute);
      return Constant(value: valueAttribute);
    }

    return node.copyWith(value: value);
  }

  @override
  Node visitCall(Call node, Context context) {
    var calling = visitExpression(node.calling, context) as Calling;
    return node.copyWith(calling: calling);
  }

  @override
  Calling visitCalling(Calling node, Context context) {
    var arguments = <Expression>[
      for (var argument in node.arguments) visitExpression(argument, context)
    ];

    var keywords = <Keyword>[
      for (var (:key, :value) in node.keywords)
        (key: key, value: visitExpression(value, context))
    ];

    Expression? dArguments;
    Expression? dKeywords;

    if (node.dArguments case var dArguments?) {
      dArguments = visitExpression(dArguments, context);
    }

    if (node.dKeywords case var dKeywords?) {
      dKeywords = visitExpression(dKeywords, context);
    }

    return Calling(
      arguments: arguments,
      keywords: keywords,
      dArguments: dArguments,
      dKeywords: dKeywords,
    );
  }

  @override
  Node visitCompare(Compare node, Context context) {
    var left = visitExpression(node.left, context);
    var right = visitExpression(node.right, context);

    if (left is Constant && right is Constant) {
      var leftValue = left.value;
      var rightValue = right.value;

      var value = switch (node.operator) {
        CompareOperator.equal => isEqual(leftValue, rightValue),
        CompareOperator.notEqual => isNotEqual(leftValue, rightValue),
        CompareOperator.lessThan => isLessThan(leftValue, rightValue),
        CompareOperator.lessThanOrEqual =>
          isLessThanOrEqual(leftValue, rightValue),
        CompareOperator.greaterThan => isGreaterThan(leftValue, rightValue),
        CompareOperator.greaterThanOrEqual =>
          isGreaterThanOrEqual(leftValue, rightValue),
        CompareOperator.contains => isIn(leftValue, rightValue),
        CompareOperator.notContains => !isIn(leftValue, rightValue),
      };

      return Constant(value: value);
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Node visitConcat(Concat node, Context context) {
    var values = <Expression>[
      for (var value in node.values) visitExpression(value, context)
    ];

    if (values.every((value) => value is Constant)) {
      var value = values
          .cast<Constant>()
          .map<Object?>((constant) => constant.value)
          .join();

      return Constant(value: value);
    }

    var newValues = <Expression>[];
    var pack = <Object?>[];

    for (var value in values) {
      if (value is Constant) {
        pack.add(value.value);
      } else {
        newValues
          ..add(Constant(value: pack.join()))
          ..add(node);

        pack.clear();
      }
    }

    if (pack.isNotEmpty) {
      newValues.add(Constant(value: pack.join()));
    }

    return node.copyWith(values: newValues);
  }

  @override
  Node visitCondition(Condition node, Context context) {
    var test = visitExpression(node.test, context);
    var trueValue = visitExpression(node.trueValue, context);
    Expression? falseValue;

    if (node.falseValue case var nodeFalseValue?) {
      falseValue = visitExpression(nodeFalseValue, context);
    }

    if (test is Constant) {
      if (boolean(test.value)) {
        return trueValue;
      } else {
        return falseValue ?? Constant(value: null);
      }
    }

    return node.copyWith(test: test, value: trueValue, falseValue: falseValue);
  }

  @override
  Node visitConstant(Constant node, Context context) {
    return node;
  }

  @override
  Node visitDict(Dict node, Context context) {
    var pairs = <Pair>[
      for (var (:key, :value) in node.pairs)
        (
          key: visitExpression(key, context),
          value: visitExpression(value, context),
        )
    ];

    if (pairs.any((pair) => pair.key is Constant && pair.value is Constant)) {
      var constantPairs = pairs.cast<({Constant key, Constant value})>();

      var value = <Object?, Object?>{
        for (var (:key, :value) in constantPairs) key.value: value.value,
      };

      return Constant(value: value);
    }

    return node.copyWith(pairs: pairs);
  }

  @override
  Node visitFilter(Filter node, Context context) {
    var calling = visitExpression(node.calling, context) as Calling;
    return node.copyWith(calling: calling);
  }

  @override
  Node visitItem(Item node, Context context) {
    var key = node.key;
    var value = node.value;

    if (key is Constant && value is Constant) {
      return Constant(value: context.item(value.value, key.value));
    }

    return node.copyWith(key: key, value: value);
  }

  @override
  Node visitLogical(Logical node, Context context) {
    var left = visitExpression(node.left, context);
    var right = visitExpression(node.right, context);

    if (left is Constant) {
      var leftValue = boolean(left.value);

      return switch (node.operator) {
        LogicalOperator.and =>
          leftValue ? visitExpression(node.right, context) : left,
        LogicalOperator.or =>
          leftValue ? left : visitExpression(node.right, context),
      };
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Node visitName(Name node, Context context) {
    return node;
  }

  @override
  Node visitNamespaceRef(NamespaceRef node, Context context) {
    return node;
  }

  @override
  Node visitScalar(Scalar node, Context context) {
    var left = visitExpression(node.left, context);
    var right = visitExpression(node.right, context);

    if (left is Constant && right is Constant) {
      var leftValue = left.value as dynamic;
      var rightValue = left.value as dynamic;

      var value = switch (node.operator) {
        ScalarOperator.power => math.pow(leftValue as num, rightValue as num),
        // ignore: avoid_dynamic_calls
        ScalarOperator.module => leftValue % rightValue,
        // ignore: avoid_dynamic_calls
        ScalarOperator.floorDivision => leftValue ~/ rightValue,
        // ignore: avoid_dynamic_calls
        ScalarOperator.division => leftValue / rightValue,
        // ignore: avoid_dynamic_calls
        ScalarOperator.multiple => leftValue * rightValue,
        // ignore: avoid_dynamic_calls
        ScalarOperator.minus => leftValue - rightValue,
        // ignore: avoid_dynamic_calls
        ScalarOperator.plus => leftValue + rightValue,
      };

      return Constant(value: value);
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Node visitTest(Test node, Context context) {
    var calling = visitExpression(node.calling, context) as Calling;
    return node.copyWith(calling: calling);
  }

  @override
  Node visitTuple(Tuple node, Context context) {
    var values = <Expression>[
      for (var value in node.values) visitExpression(value, context)
    ];

    if (values.every((value) => value is Constant)) {
      var value = values
          .cast<Constant>()
          .map<Object?>((constant) => constant.value)
          .toList();

      return Constant(value: value);
    }

    return node.copyWith(values: values);
  }

  @override
  Node visitUnary(Unary node, Context context) {
    var expression = visitExpression(node.expression, context);

    if (expression is Constant) {
      var expressionValue = expression.value as dynamic;

      var value = switch (node.operator) {
        UnaryOperator.plus => expressionValue,
        // ignore: avoid_dynamic_calls
        UnaryOperator.minus => -expressionValue,
        UnaryOperator.not => !boolean(expressionValue),
      };

      return Constant(value: value);
    }

    return node.copyWith(expression: expression);
  }

  // Statements

  List<Node> visitNodes(List<Node> nodes, Context context) {
    Node generate(int index) {
      return nodes[index].accept(this, context);
    }

    return List<Node>.generate(nodes.length, generate);
  }

  @override
  Assign visitAssign(Assign node, Context context) {
    var target = visitExpression(node.target, context);
    var value = visitExpression(node.value, context);
    return Assign(target: target, value: value);
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    var target = visitExpression(node.target, context);
    var filters = visitNodes(node.filters, context) as List<Filter>;
    var body = visitNodes(node.body, context);
    return AssignBlock(target: target, filters: filters, body: body);
  }

  @override
  AutoEscape visitAutoEscape(AutoEscape node, Context context) {
    var value = visitExpression(node.value, context);
    var body = visitNodes(node.body, context);
    return AutoEscape(value: value, body: body);
  }

  @override
  Block visitBlock(Block node, Context context) {
    var body = visitNodes(node.body, context);

    return Block(
      name: node.name,
      scoped: node.scoped,
      required: node.required,
      body: body,
    );
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Context context) {
    var call = visitExpression(node.call, context);
    var arguments = visitNodes(node.arguments, context) as List<Expression>;
    var defaults = visitNodes(node.defaults, context) as List<Expression>;
    var body = visitNodes(node.body, context);

    return CallBlock(
      call: call,
      arguments: arguments,
      defaults: defaults,
      body: body,
    );
  }

  @override
  Data visitData(Data node, Context context) {
    return node;
  }

  @override
  Do visitDo(Do node, Context context) {
    var expression = visitExpression(node.expression, context);
    return Do(expression: expression);
  }

  @override
  Extends visitExtends(Extends node, Context context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Context context) {
    var filters = visitNodes(node.filters, context) as List<Filter>;
    var body = visitNodes(node.body, context);
    return FilterBlock(filters: filters, body: body);
  }

  // TODO(optimizer): check false test
  @override
  For visitFor(For node, Context context) {
    var target = visitExpression(node.target, context);
    var iterable = visitExpression(node.iterable, context);
    var body = visitNodes(node.body, context);
    Expression? test;

    if (node.test case var nodeTest?) {
      test = visitExpression(nodeTest, context);
    }

    var orElse = visitNodes(node.orElse, context);

    return For(
      target: target,
      iterable: iterable,
      body: body,
      test: test,
      orElse: orElse,
      recursive: node.recursive,
    );
  }

  @override
  If visitIf(If node, Context context) {
    var test = visitExpression(node.test, context);
    var body = visitNodes(node.body, context);
    var orElse = visitNodes(node.orElse, context);
    return If(test: test, body: body, orElse: orElse);
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node;
  }

  @override
  Macro visitMacro(Macro node, Context context) {
    var arguments = visitNodes(node.arguments, context) as List<Expression>;
    var defaults = visitNodes(node.defaults, context) as List<Expression>;
    var body = visitNodes(node.body, context);

    return Macro(
      name: node.name,
      arguments: arguments,
      defaults: defaults,
      body: body,
    );
  }

  @override
  Node visitTemplate(Template node, Context context) {
    var blocks = visitNodes(node.blocks, context) as List<Block>;
    var body = visitNodes(node.body, context);

    return Template.parsed(
      environment: node.environment,
      path: node.path,
      blocks: blocks,
      body: body,
    );
  }

  @override
  Node visitWith(With node, Context context) {
    var targets = visitNodes(node.targets, context) as List<Expression>;
    var values = visitNodes(node.values, context) as List<Expression>;
    var body = visitNodes(node.body, context);
    return With(targets: targets, values: values, body: body);
  }
}
