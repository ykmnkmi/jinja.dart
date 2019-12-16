import '../core.dart';

class Mul extends BinaryExpression {
  Mul(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '*';

  @override
  Object resolve(Context context) {
    final Object left = this.left.resolve(context);
    final Object right = this.right.resolve(context);

    if (left is num && right is num) return left * right;
    if (left is String && right is int) return left * right;

    // TODO: исправить
    throw Exception();
  }

  @override
  String toString() => 'Mul($left, $right)';
}

class Div extends BinaryExpression {
  Div(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '/';

  @override
  num resolve(Context context) {
    final Object left = this.left.resolve(context);
    final Object right = this.right.resolve(context);

    if (left is num && right is num) return left / right;

    // TODO: исправить
    throw Exception();
  }

  @override
  String toString() => 'Div($left, $right)';
}

class FloorDiv extends BinaryExpression {
  FloorDiv(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '//';

  @override
  int resolve(Context context) {
    final Object left = this.left.resolve(context);
    final Object right = this.right.resolve(context);

    if (left is num && right is num) return left ~/ right;

    // TODO: исправить
    throw Exception();
  }

  @override
  String toString() => 'FloorDiv($left, $right)';
}

class Mod extends BinaryExpression {
  Mod(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '%';

  @override
  num resolve(Context context) {
    final Object left = this.left.resolve(context);
    final Object right = this.right.resolve(context);

    if (left is num && right is num) return left % right;

    // TODO: исправить
    throw Exception();
  }

  @override
  String toString() => 'Mod($left, $right)';
}
