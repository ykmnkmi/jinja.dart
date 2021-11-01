import 'context.dart';
import 'environment.dart';
import 'nodes.dart';
import 'utils.dart';
import 'visitor.dart';

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
    node.target = visitExpession(node.target, context);
    node.value = visitExpession(node.value, context);
    return node;
  }

  @override
  AssignBlock visitAssignBlock(AssignBlock node, Context context) {
    var filters = node.filters;

    if (filters != null) {
      visitAll(filters, context);
    }

    node.body = node.body.accept(this, context);
    node.target = visitExpession(node.target, context);
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
    node.expression = visitExpession(node.expression, context);
    return node;
  }

  @override
  Expression visitExpession(Expression node, Context context) {
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
    node.target = visitExpession(node.target, context);
    node.iterable = visitExpession(node.iterable, context);
    node.body = node.body.accept(this, context);

    var orElse = node.orElse;

    if (orElse != null) {
      node.orElse = orElse.accept(this, context);
    }

    var test = node.test;

    if (test != null) {
      var value = visitExpession(test, context);

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
    node.test = visitExpession(node.test, context);
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
  Scope visitScope(Scope node, Context context) {
    node.modifier =
        node.modifier.accept(this, context) as ScopedContextModifier;
    return node;
  }

  @override
  ScopedContextModifier visitScopedContextModifier(
      ScopedContextModifier node, Context context) {
    for (var key in node.options.keys) {
      node.options[key] = visitExpession(node.options[key]!, context);
    }

    node.body = node.body.accept(this, context);
    return node;
  }

  @override
  Template visitTemplate(Template node, Context context) {
    if (node.nodes.isNotEmpty && node.nodes.first is Extends) {
      visitAll(node.blocks, context);
    } else {
      visitAll(node.nodes, context);
    }

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
