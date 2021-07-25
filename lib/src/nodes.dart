import 'exceptions.dart';
import 'utils.dart';
import 'visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/helpers.dart';
part 'nodes/statements.dart';

typedef NodeVisitor = void Function(Node node);

abstract class ImportContext {
  bool get withContext;

  set withContext(bool withContext);
}

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, [C? context]);

  void visitChildNodes(NodeVisitor visitor) {}
}

abstract class Expression extends Node {}

abstract class Statement extends Node {}

abstract class ContextModifier extends Statement {}

abstract class Helper extends Node {}
