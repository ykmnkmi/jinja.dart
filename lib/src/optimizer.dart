import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/tests.dart';
import 'package:jinja/src/visitor.dart';

class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  // Expressions

  List<Expression> visitExpressions(
    List<Expression> expressions,
    Context context,
  ) {
    Expression generate(int index) {
      return visitExpression(expressions[index], context);
    }

    return List<Expression>.generate(expressions.length, generate);
  }

  @override
  Node visitArray(Array node, Context context) {
    var values = visitExpressions(node.values, context);

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
    throw Impossible();
  }

  @override
  Calling visitCalling(Calling node, Context context) {
    var arguments = visitExpressions(node.arguments, context);
    var keywords = visitExpressions(node.keywords, context) as List<Keyword>;
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
    var values = visitExpressions(node.values, context);

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
    throw UnimplementedError();
  }

  @override
  Node visitConstant(Constant node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitDict(Dict node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitFilter(Filter node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitItem(Item node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitKeyword(Keyword node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitLogical(Logical node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitName(Name node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitNamespaceRef(NamespaceRef node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitPair(Pair node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitScalar(Scalar node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitTest(Test node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitTuple(Tuple node, Context context) {
    throw UnimplementedError();
  }

  @override
  Node visitUnary(Unary node, Context context) {
    throw UnimplementedError();
  }

  // Statements

  List<Node> visitNodes(List<Node> nodes, Context context) {
    Node generate(int index) {
      try {
        return nodes[index].accept(this, context);
      } on Impossible {
        return nodes[index];
      }
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
  Expression visitExpression(Expression node, Context context) {
    try {
      return node.accept(this, context) as Expression;
    } on Impossible {
      return node;
    }
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
