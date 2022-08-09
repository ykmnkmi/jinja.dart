import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';

class Optimizer implements Visitor<Context, Node> {
  const Optimizer();

  @override
  void visitAll(List<Node> nodes, Context context) {
    for (var i = 0; i < nodes.length; i += 1) {
      try {
        nodes[i] = nodes[i].accept(this, context);
      } on Impossible {
        continue;
      }
    }
  }

  @override
  Assign visitAssign(Assign node, Context context) {
    node.target = visitExpression(node.target, context);
    node.value = visitExpression(node.value, context);
    return node;
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    var filters = node.filters;

    if (filters != null) {
      visitAll(filters, context);
    }

    node.body = node.body.accept(this, context);
    node.target = visitExpression(node.target, context);
    return node;
  }

  @override
  Node visitAutoEscape(AutoEscape node, Context context) {
    node.value = visitExpression(node.value, context);
    return node;
  }

  @override
  Block visitBlock(Block node, Context context) {
    node.body = node.body.accept(this, context);
    return node;
  }

  @override
  Data visitData(Data node, Context context) {
    return node;
  }

  @override
  Do visitDo(Do node, Context context) {
    node.expression = visitExpression(node.expression, context);
    return node;
  }

  @override
  Expression visitExpression(Expression node, Context context) {
    try {
      var value = node.asConst(context);
      return Constant(value);
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
    visitAll(node.filters, context);
    node.body = node.body.accept(this, context);
    return node;
  }

  @override
  For visitFor(For node, Context context) {
    node.target = visitExpression(node.target, context);
    node.iterable = visitExpression(node.iterable, context);
    node.body = node.body.accept(this, context);

    var orElse = node.orElse;

    if (orElse != null) {
      node.orElse = orElse.accept(this, context);
    }

    var test = node.test;

    if (test != null) {
      var value = visitExpression(test, context);

      if (value is Constant && boolean(value.value)) {
        node.test = null;
      } else {
        node.test = value;
      }
    }

    return node;
  }

  @override
  If visitIf(If node, Context context) {
    node.test = visitExpression(node.test, context);
    node.body = node.body.accept(this, context);

    var orElse = node.orElse;

    if (orElse != null) {
      node.orElse = orElse.accept(this, context);
    }

    return node;
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node;
  }

  @override
  Node visitOutput(Output node, Context context) {
    visitAll(node.nodes, context);
    return node;
  }

  @override
  Node visitTemplate(Template node, Context context) {
    node.body.accept(this, context);
    visitAll(node.blocks, context);
    return node;
  }

  @override
  Node visitWith(With node, Context context) {
    visitAll(node.targets, context);
    visitAll(node.values, context);
    node.body = node.body.accept(this, context);
    return node;
  }
}
