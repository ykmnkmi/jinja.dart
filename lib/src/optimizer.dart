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

    node.target = visitExpression(node.target, context);
    visitAll(node.body, context);
    return node;
  }

  @override
  Node visitAutoEscape(AutoEscape node, Context context) {
    node.value = visitExpression(node.value, context);
    return node;
  }

  @override
  Block visitBlock(Block node, Context context) {
    visitAll(node.body, context);
    return node;
  }

  @override
  CallBlock visitCallBlock(CallBlock node, Context context) {
    node.call = visitExpression(node.call, context);
    visitAll(node.arguments, context);
    visitAll(node.defaults, context);
    visitAll(node.body, context);
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
    visitAll(node.body, context);
    return node;
  }

  @override
  For visitFor(For node, Context context) {
    node.target = visitExpression(node.target, context);
    node.iterable = visitExpression(node.iterable, context);
    visitAll(node.body, context);

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }

    if (node.test != null) {
      var value = visitExpression(node.test!, context);

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
    visitAll(node.body, context);

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }

    return node;
  }

  @override
  Include visitInclude(Include node, Context context) {
    return node;
  }

  @override
  Macro visitMacro(Macro node, Context context) {
    visitAll(node.arguments, context);
    visitAll(node.defaults, context);
    visitAll(node.body, context);
    return node;
  }

  @override
  Node visitTemplate(Template node, Context context) {
    visitAll(node.blocks, context);
    visitAll(node.body, context);
    return node;
  }

  @override
  Node visitWith(With node, Context context) {
    visitAll(node.targets, context);
    visitAll(node.values, context);
    visitAll(node.body, context);
    return node;
  }
}
