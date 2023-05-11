import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  List<Node> visitAll(List<Node> nodes, Context context) {
    Node generate(int index) {
      try {
        return nodes[index].accept(this, context);
      } on Impossible {
        return nodes[index];
      }
    }

    return List<Node>.generate(nodes.length, generate);
  }

  // Expressions
  // ...

  // Statements

  @override
  Assign visitAssign(Assign node, Context context) {
    var target = visitExpression(node.target, context);
    var value = visitExpression(node.value, context);
    return Assign(target: target, value: value);
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    var target = visitExpression(node.target, context);
    var filters = visitAll(node.filters, context) as List<Filter>;
    var body = visitAll(node.body, context);
    return AssignBlock(target: target, filters: filters, body: body);
  }

  @override
  AutoEscape visitAutoEscape(AutoEscape node, Context context) {
    var value = visitExpression(node.value, context);
    var body = visitAll(node.body, context);
    return AutoEscape(value: value, body: body);
  }

  @override
  Block visitBlock(Block node, Context context) {
    var body = visitAll(node.body, context);

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
    var arguments = visitAll(node.arguments, context) as List<Expression>;
    var defaults = visitAll(node.defaults, context) as List<Expression>;
    var body = visitAll(node.body, context);

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
    return node.accept(this, context) as Expression;
  }

  @override
  Extends visitExtends(Extends node, Context context) {
    return node;
  }

  @override
  FilterBlock visitFilterBlock(FilterBlock node, Context context) {
    var filters = visitAll(node.filters, context) as List<Filter>;
    var body = visitAll(node.body, context);
    return FilterBlock(filters: filters, body: body);
  }

  // TODO(optimizer): check false test
  @override
  For visitFor(For node, Context context) {
    var target = visitExpression(node.target, context);
    var iterable = visitExpression(node.iterable, context);
    var body = visitAll(node.body, context);
    Expression? test;

    if (node.test case var nodeTest?) {
      test = visitExpression(nodeTest, context);
    }

    var orElse = visitAll(node.orElse, context);

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
    var body = visitAll(node.body, context);
    var orElse = visitAll(node.orElse, context);
    return If(test: test, body: body, orElse: orElse);
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node;
  }

  @override
  Macro visitMacro(Macro node, Context context) {
    var arguments = visitAll(node.arguments, context) as List<Expression>;
    var defaults = visitAll(node.defaults, context) as List<Expression>;
    var body = visitAll(node.body, context);

    return Macro(
      name: node.name,
      arguments: arguments,
      defaults: defaults,
      body: body,
    );
  }

  @override
  Node visitTemplate(Template node, Context context) {
    var blocks = visitAll(node.blocks, context) as List<Block>;
    var body = visitAll(node.body, context);

    return Template.parsed(
      environment: node.environment,
      path: node.path,
      blocks: blocks,
      body: body,
    );
  }

  @override
  Node visitWith(With node, Context context) {
    var targets = visitAll(node.targets, context) as List<Expression>;
    var values = visitAll(node.values, context) as List<Expression>;
    var body = visitAll(node.body, context);
    return With(targets: targets, values: values, body: body);
  }
}
