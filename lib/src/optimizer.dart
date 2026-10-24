import 'dart:math' as math;

import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';
import 'package:meta/meta.dart';

@doNotStore
class Optimizer implements Visitor<Environment, Node> {
  const new();

  T visitNode<T extends Node?>(Node? node, Environment context) {
    return node?.accept(this, context) as T;
  }

  List<T> visitNodes<T extends Node>(List<Node> nodes, Environment context) {
    return List<T>.generate(
      nodes.length,
      (i) => visitNode<T>(nodes[i], context),
    );
  }

  List<T>? visitNullNodes<T extends Node>(
    List<Node>? nodes,
    Environment context,
  ) {
    if (nodes == null) {
      return null;
    }

    return visitNodes<T>(nodes, context);
  }

  // Helpers

  @override
  Keyword visitKeyword(Keyword node, Environment context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Named visitNamed(Named node, Environment context) {
    return node.copyWith(
      argument: visitNode<Expression>(node.argument, context),
      defaultValue: visitNode<Expression>(node.defaultValue, context),
    );
  }

  @override
  Operand visitOperand(Operand node, Environment context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Pair visitPair(Pair node, Environment context) {
    return node.copyWith(
      key: visitNode<Expression>(node.key, context),
      value: visitNode<Expression>(node.value, context),
    );
  }

  // Expressions

  @override
  Expression visitArray(Array node, Environment context) {
    var values = visitNodes<Expression>(node.values, context);
    var value = List<Object?>.filled(values.length, null, growable: true);

    for (var i = 0; i < values.length; i++) {
      if (values[i] case Constant constant) {
        value[i] = constant.value;
      } else {
        return node.copyWith(values: values);
      }
    }

    return Constant(value: value);
  }

  @override
  Expression visitAttribute(Attribute node, Environment context) {
    return node.copyWith(value: visitNode<Expression>(node.value, context));
  }

  @override
  Call visitCall(Call node, Environment context) {
    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Calling visitCalling(Calling node, Environment context) {
    return node.copyWith(
      arguments: visitNodes<Expression>(node.arguments, context),
      keywords: visitNodes<Keyword>(node.keywords, context),
    );
  }

  @override
  Expression visitCompare(Compare node, Environment context) {
    return node.copyWith(
      value: visitNode<Expression>(node.value, context),
      operands: visitNodes<Operand>(node.operands, context),
    );
  }

  @override
  Expression visitConcat(Concat node, Environment context) {
    var values = visitNodes<Expression>(node.values, context);
    var newValues = <Expression>[];
    var buffer = StringBuffer();

    for (var i = 0; i < values.length; i++) {
      if (values[i] case Constant constant) {
        buffer.write(constant.value);
      } else {
        if (buffer.isNotEmpty) {
          newValues.add(Constant(value: buffer.toString()));
          buffer.clear();
        }

        newValues.add(values[i]);
      }
    }

    if (buffer.isNotEmpty) {
      newValues.add(Constant(value: buffer.toString()));
    }

    // The parser always returns a concatenation with at least two nodes.
    return switch (newValues.length) {
      0 => Constant(value: ''),
      1 => newValues[0],
      _ => node.copyWith(values: newValues),
    };
  }

  @override
  Expression visitCondition(Condition node, Environment context) {
    var test = visitNode<Expression>(node.test, context);
    var trueValue = visitNode<Expression>(node.trueValue, context);
    var falseValue = visitNode<Expression?>(node.falseValue, context);

    if (test is Constant) {
      if (boolean(test.value)) {
        return trueValue;
      }

      return falseValue ?? const Constant(value: null);
    }

    return node.copyWith(
      test: test,
      trueValue: trueValue,
      falseValue: falseValue,
    );
  }

  @override
  Constant visitConstant(Constant node, Environment context) {
    return node;
  }

  @override
  Expression visitDict(Dict node, Environment context) {
    var pairs = visitNodes<Pair>(node.pairs, context);
    var newValue = <Object?, Object?>{};

    for (var i = 0; i < pairs.length; i++) {
      if (pairs[i] case Pair(key: Constant key, value: Constant value)) {
        newValue[key.value] = value.value;
      } else {
        return node.copyWith(pairs: pairs);
      }
    }

    return Constant(value: newValue);
  }

  @override
  Filter visitFilter(Filter node, Environment context) {
    return node.copyWith(
      expression: visitNode<Expression?>(node.expression, context),
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Expression visitItem(Item node, Environment context) {
    var key = visitNode<Expression>(node.key, context);
    var value = visitNode<Expression>(node.value, context);

    if (key is Constant && value is Constant) {
      return Constant(value: context.getItem(key.value, value.value));
    }

    return node.copyWith(key: key, value: value);
  }

  @override
  Expression visitLogical(Logical node, Environment context) {
    var left = visitNode<Expression>(node.left, context);
    var right = visitNode<Expression>(node.right, context);

    if (left is Constant) {
      return switch (node.operator) {
        LogicalOperator.and => boolean(left.value) ? right : left,
        LogicalOperator.or => boolean(left.value) ? left : right,
      };
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Name visitName(Name node, Environment context) {
    return node;
  }

  @override
  NsRef visitNsRef(NsRef node, Environment context) {
    return node;
  }

  @override
  Expression visitScalar(Scalar node, Environment context) {
    var left = visitNode<Expression>(node.left, context);
    var right = visitNode<Expression>(node.right, context);

    if (left is Constant && right is Constant) {
      return Constant(
        value: switch (node.operator) {
          ScalarOperator.power => math.pow(
            left.value as num,
            right.value as num,
          ),
          // TODO(dynamic): dynamic invocation
          ScalarOperator.module => (left.value as dynamic) % right.value,
          ScalarOperator.floorDivision =>
            // TODO(dynamic): dynamic invocation
            (left.value as dynamic) ~/ right.value,
          // TODO(dynamic): dynamic invocation
          ScalarOperator.division => (left.value as dynamic) / right.value,
          // TODO(dynamic): dynamic invocation
          ScalarOperator.multiple => (left.value as dynamic) * right.value,
          // TODO(dynamic): dynamic invocation
          ScalarOperator.minus => (left.value as dynamic) - right.value,
          // TODO(dynamic): dynamic invocation
          ScalarOperator.plus => (left.value as dynamic) + right.value,
        },
      );
    }

    return node.copyWith(left: left, right: right);
  }

  @override
  Slice visitSlice(Slice node, Environment context) {
    return node.copyWith(
      start: visitNode<Expression?>(node.start, context),
      stop: visitNode<Expression?>(node.stop, context),
      step: visitNode<Expression?>(node.step, context),
    );
  }

  @override
  Test visitTest(Test node, Environment context) {
    return node.copyWith(
      expression: visitNode<Expression>(node.expression, context),
      calling: visitNode<Calling>(node.calling, context),
    );
  }

  @override
  Expression visitTuple(Tuple node, Environment context) {
    var values = visitNodes<Expression>(node.values, context);
    var newValues = List<Object?>.filled(values.length, null);

    for (var i = 0; i < values.length; i++) {
      if (values[i] case Constant constant) {
        newValues[i] = constant.value;
      } else {
        return node.copyWith(values: values);
      }
    }

    return Constant(value: newValues);
  }

  @override
  Expression visitUnary(Unary node, Environment context) {
    var value = visitNode<Expression>(node.value, context);

    if (value is Constant) {
      return Constant(
        value: switch (node.operator) {
          UnaryOperator.plus => value.value,
          // TODO(dynamic): dynamic invocation
          UnaryOperator.minus => -(value.value as dynamic),
          UnaryOperator.not => !boolean(value.value),
        },
      );
    }

    return node.copyWith(value: value);
  }

  // Statements

  @override
  Assign visitAssign(Assign node, Environment context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      value: visitNode<Expression>(node.value, context),
    );
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Environment context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      filter: visitNode<Filter?>(node.filter, context),
      nodes: visitNodes<Node>(node.nodes, context),
    );
  }

  @override
  Block visitBlock(Block node, Environment context) {
    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Environment context) {
    return node.copyWith(
      call: visitNode<Call>(node.call, context),
      positional: visitNodes<Expression>(node.positional, context),
      named: visitNodes<Named>(node.named, context),
      nodes: visitNodes<Node>(node.nodes, context),
    );
  }

  @override
  Data visitData(Data node, Environment context) {
    return node;
  }

  @override
  Do visitDo(Do node, Environment context) {
    return node.copyWith(
      expressions: visitNodes<Expression>(node.expressions, context),
    );
  }

  @override
  Extends visitExtends(Extends node, Environment context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Environment context) {
    return node.copyWith(
      filter: visitNode<Filter?>(node.filter, context),
      nodes: visitNodes<Node>(node.nodes, context),
    );
  }

  // TODO(optimizer): check false test
  @override
  For visitFor(For node, Environment context) {
    return node.copyWith(
      target: visitNode<Expression>(node.target, context),
      iterable: visitNode<Expression>(node.iterable, context),
      nodes: visitNodes<Node>(node.nodes, context),
      test: visitNode<Expression?>(node.test, context),
      elseNodes: visitNullNodes<Node>(node.elseNodes, context),
    );
  }

  @override
  FromImport visitFromImport(FromImport node, Environment context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  If visitIf(If node, Environment context) {
    return node.copyWith(
      test: visitNode<Expression>(node.test, context),
      nodes: visitNodes<Node>(node.nodes, context),
      elseIfNodes: visitNullNodes<If>(node.elseIfNodes, context),
      elseNodes: visitNullNodes<Node>(node.elseNodes, context),
    );
  }

  @override
  Import visitImport(Import node, Environment context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Include visitInclude(Include node, Environment context) {
    return node.copyWith(
      template: visitNode<Expression>(node.template, context),
    );
  }

  @override
  Macro visitMacro(Macro node, Environment context) {
    return node.copyWith(
      positional: visitNodes<Expression>(node.positional, context),
      named: visitNodes<Named>(node.named, context),
      nodes: visitNodes<Node>(node.nodes, context),
    );
  }

  @override
  Output visitOutput(Output node, Environment context) {
    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  TemplateNode visitTemplateNode(TemplateNode node, Environment context) {
    return node.copyWith(nodes: visitNodes<Node>(node.nodes, context));
  }

  @override
  Node visitTryCatch(TryCatch node, Environment context) {
    return node.copyWith(
      nodes: visitNodes<Node>(node.nodes, context),
      exception: visitNode<Name?>(node.exception, context),
      catchNodes: visitNodes<Node>(node.catchNodes, context),
    );
  }

  @override
  Node visitWith(With node, Environment context) {
    return node.copyWith(
      targets: visitNodes<Expression>(node.targets, context),
      values: visitNodes<Expression>(node.values, context),
      nodes: visitNodes<Node>(node.nodes, context),
    );
  }

  static T optimize<T extends Node>(T node, Environment environment) {
    return node.accept(const Optimizer(), environment) as T;
  }
}
