import '../context.dart';

export '../context.dart';
export '../utils.dart';

abstract class Node {
  void accept(StringBuffer buffer, Context context);

  String toDebugString([int level = 0]) => ' ' * level + toString();
}

abstract class Statement extends Node {}

abstract class Expression extends Node {
  dynamic resolve(Context context);

  @override
  void accept(StringBuffer buffer, Context context) {
    buffer.write(resolve(context));
  }
}

abstract class UnaryExpression extends Expression {
  Expression get expr;
  String get symbol;

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + '$symbol${expr.toDebugString()}';
}

abstract class BinaryExpression extends Expression {
  Expression get left;
  Expression get right;
  String get symbol;

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + '${left.toDebugString()} $symbol ${right.toDebugString()}';
}

abstract class Assignable {
  List<String> get keys;
  bool get canAssign => false;
}
