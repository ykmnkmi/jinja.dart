import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

abstract class RuntimeCompiler<C, R> implements Visitor<C, R> {
  const RuntimeCompiler();

  // Expressions

  @override
  R visitArray(Array node, C context);

  @override
  R visitAttribute(Attribute node, C context);

  @override
  R visitCall(Call node, C context);

  @override
  R visitCalling(Calling node, C context);

  @override
  R visitCompare(Compare node, C context);

  @override
  R visitConcat(Concat node, C context);

  @override
  R visitCondition(Condition node, C context);

  @override
  R visitConstant(Constant node, C context);

  @override
  R visitDict(Dict node, C context);

  @override
  R visitFilter(Filter node, C context);

  @override
  R visitItem(Item node, C context);

  @override
  R visitLogical(Logical node, C context);

  @override
  R visitName(Name node, C context);

  @override
  R visitNamespaceRef(NamespaceRef node, C context);

  @override
  R visitScalar(Scalar node, C context);

  @override
  R visitTest(Test node, C context);

  @override
  R visitTuple(Tuple node, C context);

  @override
  R visitUnary(Unary node, C context);

  // Statements

  @override
  R visitAssign(Assign node, C context);

  @override
  R visitAssignBlock(AssignBlock node, C context);

  @override
  R visitAutoEscape(AutoEscape node, C context);

  @override
  R visitBlock(Block node, C context);

  @override
  R visitCallBlock(CallBlock node, C context);

  @override
  R visitData(Data node, C context);

  @override
  R visitDo(Do node, C context);

  @override
  R visitExtends(Extends node, C context);

  @override
  R visitFilterBlock(FilterBlock node, C context);

  @override
  R visitFor(For node, C context);

  @override
  R visitIf(If node, C context);

  @override
  R visitInclude(Include node, C context);

  @override
  R visitInterpolation(Interpolation node, C context);

  @override
  R visitMacro(Macro node, C context);

  @override
  R visitOutput(Output node, C context);

  @override
  R visitTemplateNode(TemplateNode node, C context);

  @override
  R visitWith(With node, C context);
}
