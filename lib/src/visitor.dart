import 'environment.dart';
import 'nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  void visitAll(List<Node> nodes, C context) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  R visitAssign(Assign node, C context);

  R visitAssignBlock(AssignBlock node, C context);

  R visitBlock(Block node, C context);

  R visitData(Data node, C context);

  R visitDo(Do node, C context);

  R visitExpession(Expression expression, C context);

  R visitExtends(Extends node, C context);

  R visitFilterBlock(FilterBlock node, C context);

  R visitFor(For node, C context);

  R visitIf(If node, C context);

  R visitInclude(Include node, C context);

  R visitScope(Scope node, C context);

  R visitTemplate(Template node, C context);

  R visitWith(With node, C context);
}
