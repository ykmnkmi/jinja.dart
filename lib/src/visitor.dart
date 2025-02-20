import 'package:jinja/src/nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  // Expressions

  R visitArray(Array node, C context);

  R visitAttribute(Attribute node, C context);

  R visitCall(Call node, C context);

  R visitCalling(Calling node, C context);

  R visitCompare(Compare node, C context);

  R visitConcat(Concat node, C context);

  R visitCondition(Condition node, C context);

  R visitConstant(Constant node, C context);

  R visitDict(Dict node, C context);

  R visitFilter(Filter node, C context);

  R visitItem(Item node, C context);

  R visitLogical(Logical node, C context);

  R visitName(Name node, C context);

  R visitNamespaceRef(NamespaceRef node, C context);

  R visitScalar(Scalar node, C context);

  R visitTest(Test node, C context);

  R visitTuple(Tuple node, C context);

  R visitUnary(Unary node, C context);

  // Statements

  R visitAssign(Assign node, C context);

  R visitAssignBlock(AssignBlock node, C context);

  R visitBlock(Block node, C context);

  R visitCallBlock(CallBlock node, C context);

  R visitData(Data node, C context);

  R visitDo(Do node, C context);

  R visitExtends(Extends node, C context);

  R visitFilterBlock(FilterBlock node, C context);

  R visitFor(For node, C context);

  R visitFromImport(FromImport node, C context);

  R visitIf(If node, C context);

  R visitImport(Import node, C context);

  R visitInclude(Include node, C context);

  R visitInterpolation(Interpolation node, C context);

  R visitMacro(Macro node, C context);

  R visitOutput(Output node, C context);

  R visitTemplateNode(TemplateNode node, C context);

  R visitWith(With node, C context);

  R visitSlice(Slice node, C context) {
    throw UnimplementedError();
  }
}

class ThrowingVisitor<C, R> implements Visitor<C, R> {
  const ThrowingVisitor();

  // Expressions

  @override
  R visitArray(Array node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitAttribute(Attribute node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitCall(Call node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitCalling(Calling node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitCompare(Compare node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitConcat(Concat node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitCondition(Condition node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitConstant(Constant node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitDict(Dict node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitFilter(Filter node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitItem(Item node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitLogical(Logical node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitName(Name node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitNamespaceRef(NamespaceRef node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitScalar(Scalar node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitTest(Test node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitTuple(Tuple node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitUnary(Unary node, C context) {
    throw UnimplementedError();
  }

  // Statements

  @override
  R visitAssign(Assign node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitAssignBlock(AssignBlock node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitBlock(Block node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitCallBlock(CallBlock node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitData(Data node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitDo(Do node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitExtends(Extends node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitFilterBlock(FilterBlock node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitFor(For node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitFromImport(FromImport node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitIf(If node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitImport(Import node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitInclude(Include node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitInterpolation(Interpolation node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitMacro(Macro node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitOutput(Output node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitTemplateNode(TemplateNode node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitWith(With node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitSlice(Slice node, C context) {
    throw UnimplementedError();
  }
}
