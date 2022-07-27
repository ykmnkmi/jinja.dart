import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/visitor.dart';

class Frame {
  Frame(this.environment);

  final Environment environment;
}

class Compiler extends Visitor<Frame, void> {
  const Compiler();

  @override
  void visitAssign(Assign node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitAssignBlock(AssignBlock node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitAutoEscape(AutoEscape node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitBlock(Block node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitData(Data node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitDo(Do node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitExpression(Expression node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitExtends(Extends node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitFilterBlock(FilterBlock node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitFor(For node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitIf(If node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitInclude(Include node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitOutput(Output node, Frame context) {
    throw UnimplementedError();
  }

  @override
  void visitTemplate(Template node, Frame context) {
    visitAll(node.blocks, context);
    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, Frame context) {
    throw UnimplementedError();
  }

  static void compile(Node node, Environment environment) {
    var visitor = const Compiler();
    var context = Frame(environment);
    node.accept(visitor, context);
  }
}
