import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';

typedef ExpressionUpdater = Expression Function(Expression expression);

abstract class Visitor<C, R> {
  const Visitor();

  void visitAll(List<Node> nodes, C context) {
    for (var node in nodes) {
      node.accept(this, context);
    }
  }

  R visitAssign(Assign node, C context);

  R visitAssignBlock(AssignBlock node, C context);

  R visitAutoEscape(AutoEscape node, C context);

  R visitBlock(Block node, C context);

  R visitCallBlock(CallBlock node, C context);

  R visitData(Data node, C context);

  R visitDo(Do node, C context);

  R visitExpression(Expression node, C context);

  R visitExtends(Extends node, C context);

  R visitFilterBlock(FilterBlock node, C context);

  R visitFor(For node, C context);

  R visitIf(If node, C context);

  R visitInclude(Include node, C context);

  R visitMacro(Macro node, C context);

  R visitTemplate(Template node, C context);

  R visitWith(With node, C context);
}

abstract class ThrowingVisitor<C, R> implements Visitor<C, R> {
  const ThrowingVisitor();

  Never fail(Node node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  void visitAll(List<Node> nodes, C context) {
    for (var node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  R visitAssign(Assign node, C context) {
    fail(node, context);
  }

  @override
  R visitAssignBlock(AssignBlock node, C context) {
    fail(node, context);
  }

  @override
  R visitBlock(Block node, C context) {
    fail(node, context);
  }

  @override
  R visitCallBlock(CallBlock node, C context) {
    fail(node, context);
  }

  @override
  R visitData(Data node, C context) {
    fail(node, context);
  }

  @override
  R visitDo(Do node, C context) {
    fail(node, context);
  }

  @override
  R visitExpression(Expression node, C context) {
    fail(node, context);
  }

  @override
  R visitExtends(Extends node, C context) {
    fail(node, context);
  }

  @override
  R visitFilterBlock(FilterBlock node, C context) {
    fail(node, context);
  }

  @override
  R visitFor(For node, C context) {
    fail(node, context);
  }

  @override
  R visitIf(If node, C context) {
    fail(node, context);
  }

  @override
  R visitInclude(Include node, C context) {
    fail(node, context);
  }

  @override
  R visitMacro(Macro node, C context) {
    fail(node, context);
  }

  @override
  R visitTemplate(Template node, C context) {
    fail(node, context);
  }

  @override
  R visitWith(With node, C context) {
    fail(node, context);
  }
}

class ExpressionMapper extends Visitor<ExpressionUpdater, void> {
  const ExpressionMapper();

  @override
  void visitAll(List<Node> nodes, ExpressionUpdater context) {
    for (var i = 0; i < nodes.length; i += 1) {
      var node = nodes[i];

      if (node is Expression) {
        nodes[i] = visitExpression(node, context);
      } else {
        node.accept(this, context);
      }
    }
  }

  @override
  void visitAssign(Assign node, ExpressionUpdater context) {
    node.target = visitExpression(node.target, context);
    node.value = visitExpression(node.value, context);
  }

  @override
  void visitAssignBlock(AssignBlock node, ExpressionUpdater context) {
    node.target = visitExpression(node.target, context);
    visitAll(node.body, context);

    if (node.filters != null) {
      visitAll(node.filters!, context);
    }
  }

  @override
  void visitAutoEscape(AutoEscape node, ExpressionUpdater context) {
    node.value = visitExpression(node.value, context);
  }

  @override
  void visitBlock(Block node, ExpressionUpdater context) {
    visitAll(node.body, context);
  }

  @override
  void visitData(Data node, ExpressionUpdater context) {}

  @override
  void visitDo(Do node, ExpressionUpdater context) {
    node.expression = visitExpression(node.expression, context);
  }

  @override
  void visitCallBlock(CallBlock node, ExpressionUpdater context) {
    node.call = visitExpression(node.call, context);
    visitAll(node.arguments, context);
    visitAll(node.defaults, context);
    visitAll(node.body, context);
  }

  @override
  Expression visitExpression(Expression node, ExpressionUpdater context) {
    node.update(context);
    return context(node);
  }

  @override
  void visitExtends(Extends node, ExpressionUpdater context) {}

  @override
  void visitFilterBlock(FilterBlock node, ExpressionUpdater context) {
    visitAll(node.filters, context);
    visitAll(node.body, context);
  }

  @override
  void visitFor(For node, ExpressionUpdater context) {
    node.target = visitExpression(node.target, context);
    node.iterable = visitExpression(node.iterable, context);

    if (node.test != null) {
      node.test = visitExpression(node.test!, context);
    }

    visitAll(node.body, context);

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }
  }

  @override
  void visitIf(If node, ExpressionUpdater context) {
    node.test = visitExpression(node.test, context);
    visitAll(node.body, context);

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }
  }

  @override
  void visitInclude(Include node, ExpressionUpdater context) {}

  @override
  void visitMacro(Macro node, ExpressionUpdater context) {
    visitAll(node.arguments, context);
    visitAll(node.defaults, context);
    visitAll(node.body, context);
  }

  @override
  void visitTemplate(Template node, ExpressionUpdater context) {
    visitAll(node.blocks, context);
    visitAll(node.body, context);
  }

  @override
  void visitWith(With node, ExpressionUpdater context) {
    visitAll(node.targets, context);
    visitAll(node.values, context);
    visitAll(node.body, context);
  }
}
