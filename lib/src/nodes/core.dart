import '../context.dart';
import '../markup.dart';
import '../utils.dart';

export '../context.dart';
export '../utils.dart';

class Imposible implements Exception {}

abstract class Node {
  void accept(StringBuffer buffer, Context context);

  String toDebugString([int level = 0]);
}

abstract class Statement implements Node {}

abstract class Expression implements Node {
  Object resolve(Context context) => null;

  @override
  void accept(StringBuffer buffer, Context context) {
    Object value = resolve(context);

    if (value is Node) {
      value.accept(buffer, context);
    } else {
      value = context.env.finalize(value);

      if (context.env.autoEscape) {
        value = Markup.escape(value.toString());
      }

      buffer.write(value);
    }
  }
}

abstract class UnaryExpression extends Expression {
  Expression get expr;
  String get symbol;

  @override
  String toDebugString([int level = 0]) => ' ' * level + '$symbol${expr.toDebugString()}';
}

abstract class BinaryExpression extends Expression {
  Expression get left;
  Expression get right;
  String get symbol;

  @override
  String toDebugString([int level = 0]) => ' ' * level + '${left.toDebugString()} $symbol ${right.toDebugString()}';
}

abstract class CanAssign {
  List<String> get keys;
  bool get canAssign => false;
}

abstract class CanConst {
  bool canConst;
  Literal<Object> get asConst;
}

class Name extends Expression implements CanAssign {
  Name(this.name);

  final String name;

  @override
  dynamic resolve(Context context) => context[name];

  @override
  bool get canAssign => true;

  @override
  List<String> get keys => <String>[name];

  @override
  String toDebugString([int level = 0]) => ' ' * level + name;

  @override
  String toString() => 'Name($name)';
}

class Literal<T> extends Expression {
  Literal(this.value);

  final T value;

  @override
  T resolve(Context context) => value;

  @override
  String toDebugString([int level = 0]) => ' ' * level + repr(value);

  @override
  String toString() => 'Literal($value)';
}
