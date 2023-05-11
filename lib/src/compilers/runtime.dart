import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

class RuntimeCompiler implements Visitor<Object?, void> {
  const RuntimeCompiler();

  // Expressions

  @override
  void visitArray(Array node, Object? context) {}

  @override
  void visitAttribute(Attribute node, Object? context) {}

  @override
  void visitCall(Call node, Object? context) {}

  @override
  void visitCompare(Compare node, Object? context) {}

  @override
  void visitConcat(Concat node, Object? context) {}

  @override
  void visitCondition(Condition node, Object? context) {}

  @override
  void visitConstant(Constant node, Object? context) {}

  @override
  void visitDict(Dict node, Object? context) {}

  @override
  void visitFilter(Filter node, Object? context) {}

  @override
  void visitItem(Item node, Object? context) {}

  @override
  void visitKeyword(Keyword node, Object? context) {}

  @override
  void visitLogical(Logical node, Object? context) {}

  @override
  void visitName(Name node, Object? context) {}

  @override
  void visitNamespaceRef(NamespaceRef node, Object? context) {}

  @override
  void visitOperand(Operand node, Object? context) {}

  @override
  void visitPair(Pair node, Object? context) {}

  @override
  void visitScalar(Scalar node, Object? context) {}

  @override
  void visitTest(Test node, Object? context) {}

  @override
  void visitTuple(Tuple node, Object? context) {}

  @override
  void visitUnary(Unary node, Object? context) {}

  // Statements

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
