import 'environment.dart';
import 'nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  void visitAll(List<Node> nodes, C context) {
    for (var node in nodes) {
      node.accept(this, context);
    }
  }

  R visitAssign(Assign node, C context);

  R visitAssignBlock(AssignBlock node, C context);

  R visitBlock(Block node, C context);

  R visitData(Data node, C context);

  R visitDo(Do node, C context);

  R visitExpession(Expression node, C context);

  R visitExtends(Extends node, C context);

  R visitFilterBlock(FilterBlock node, C context);

  R visitFor(For node, C context);

  R visitIf(If node, C context);

  R visitInclude(Include node, C context);

  R visitOutput(Output node, C context);

  R visitScope(Scope node, C context);

  R visitScopedContextModifier(ScopedContextModifier node, C context);

  R visitTemplate(Template node, C context);

  R visitWith(With node, C context);
}

abstract class ThrowingVisitor<C, R> implements Visitor<C, R> {
  const ThrowingVisitor();

  Never fail(Node node, C context) {
    throw UnimplementedError(node.runtimeType.toString());
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
  R visitData(Data node, C context) {
    fail(node, context);
  }

  @override
  R visitDo(Do node, C context) {
    fail(node, context);
  }

  @override
  R visitExpession(Expression node, C context) {
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
  R visitOutput(Output node, C context) {
    fail(node, context);
  }

  @override
  R visitScope(Scope node, C context) {
    fail(node, context);
  }

  @override
  R visitScopedContextModifier(ScopedContextModifier node, C context) {
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

typedef ExpressionMapper = Expression Function(Expression expression);

class ExpressionVisitor extends ThrowingVisitor<ExpressionMapper, void> {
  const ExpressionVisitor();
}
