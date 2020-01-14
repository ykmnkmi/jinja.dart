import '../core.dart';

class Mul extends BinaryExpression {
  Mul(this.left, this.right) : symbol = '*';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final symbol;

  @override
  Object resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return left * right;
    }

    if (left is String && right is int) {
      return left * right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'Mul($left, $right)';
  }
}

class Div extends BinaryExpression {
  Div(this.left, this.right) : symbol = '/';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final symbol;

  @override
  num resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return left / right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'Div($left, $right)';
  }
}

class FloorDiv extends BinaryExpression {
  FloorDiv(this.left, this.right) : symbol = '//';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final symbol;

  @override
  int resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return left ~/ right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'FloorDiv($left, $right)';
  }
}

class Mod extends BinaryExpression {
  Mod(this.left, this.right) : symbol = '%';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final symbol;

  @override
  num resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return left % right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'Mod($left, $right)';
  }
}
