import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

class RuntimeCompiler extends Visitor<Object?, void> {
  @override
  void visitAssign(Assign node, Object? context) {}

  @override
  void visitAssignBlock(AssignBlock node, Object? context) {}

  @override
  void visitAutoEscape(AutoEscape node, Object? context) {}

  @override
  void visitBlock(Block node, Object? context) {}

  @override
  void visitCallBlock(CallBlock node, Object? context) {}

  @override
  void visitData(Data node, Object? context) {}

  @override
  void visitDo(Do node, Object? context) {}

  @override
  void visitExpression(Expression node, Object? context) {}

  @override
  void visitExtends(Extends node, Object? context) {}

  @override
  void visitFilterBlock(FilterBlock node, Object? context) {}

  @override
  void visitFor(For node, Object? context) {}

  @override
  void visitIf(If node, Object? context) {}

  @override
  void visitInclude(Include node, Object? context) {}

  @override
  void visitMacro(Macro node, Object? context) {}

  @override
  void visitTemplate(Template node, Object? context) {}

  @override
  void visitWith(With node, Object? context) {}
}
