import 'package:jinja/src/context.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/visitor.dart';

abstract class Compiler<T> extends Visitor<Context, T> {}

class RuntimeCompiler extends Compiler<void> {
  @override
  void visitAssign(Assign node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitAssignBlock(AssignBlock node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitAutoEscape(AutoEscape node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitBlock(Block node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitData(Data node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitDo(Do node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitExpession(Expression node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitExtends(Extends node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitFilterBlock(FilterBlock node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitFor(For node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitIf(If node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitInclude(Include node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitOutput(Output node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitTemplate(Template node, Context context) {
    throw UnimplementedError();
  }

  @override
  void visitWith(With node, Context context) {
    throw UnimplementedError();
  }
}
