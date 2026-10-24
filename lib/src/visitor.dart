import 'package:jinja/src/nodes.dart';

abstract interface class Visitor<C, R> {
  const new();

  // Helpers

  R visitKeyword(Keyword node, C context);

  R visitNamed(Named node, C context);

  R visitOperand(Operand node, C context);

  R visitPair(Pair node, C context);

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

  R visitNsRef(NsRef node, C context);

  R visitScalar(Scalar node, C context);

  R visitSlice(Slice node, C context);

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

  R visitMacro(Macro node, C context);

  R visitOutput(Output node, C context);

  R visitTemplateNode(TemplateNode node, C context);

  R visitTryCatch(TryCatch node, C context);

  R visitWith(With node, C context);
}

base class ThrowingVisitor<C, R> implements Visitor<C, R> {
  const new();

  // Helpers

  @override
  R visitKeyword(Keyword node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitNamed(Named node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitOperand(Operand node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitPair(Pair node, C context) {
    throw UnimplementedError();
  }

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
  R visitNsRef(NsRef node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitScalar(Scalar node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitSlice(Slice node, C context) {
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
  R visitTryCatch(TryCatch node, C context) {
    throw UnimplementedError();
  }

  @override
  R visitWith(With node, C context) {
    throw UnimplementedError();
  }
}

base class ChildVisitor<C> extends Visitor<C, void> {
  const new();

  void visitChildren(Node node, C context) {
    for (var child in node.childNodes) {
      child.accept<C, void>(this, context);
    }
  }

  // Helpers

  @override
  void visitKeyword(Keyword node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitNamed(Named node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitOperand(Operand node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitPair(Pair node, C context) {
    visitChildren(node, context);
  }

  // Expressions

  @override
  void visitArray(Array node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitAttribute(Attribute node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitCall(Call node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitCalling(Calling node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitCompare(Compare node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitConcat(Concat node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitCondition(Condition node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitConstant(Constant node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitDict(Dict node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitFilter(Filter node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitItem(Item node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitLogical(Logical node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitName(Name node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitNsRef(NsRef node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitScalar(Scalar node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitSlice(Slice node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitTest(Test node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitTuple(Tuple node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitUnary(Unary node, C context) {
    visitChildren(node, context);
  }

  // Statements

  @override
  void visitAssign(Assign node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitAssignBlock(AssignBlock node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitBlock(Block node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitCallBlock(CallBlock node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitData(Data node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitDo(Do node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitExtends(Extends node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitFilterBlock(FilterBlock node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitFor(For node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitFromImport(FromImport node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitIf(If node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitImport(Import node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitInclude(Include node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitMacro(Macro node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitOutput(Output node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitTemplateNode(TemplateNode node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitTryCatch(TryCatch node, C context) {
    visitChildren(node, context);
  }

  @override
  void visitWith(With node, C context) {
    visitChildren(node, context);
  }
}
