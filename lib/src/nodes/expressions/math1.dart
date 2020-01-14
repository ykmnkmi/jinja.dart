import '../core.dart';

class Add extends BinaryExpression {
  Add(this.left, this.right) : symbol = '+';

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
      return left + right;
    }

    if (left is String && right is String) {
      return left + right;
    }

    if (left is List && right is List) {
      return left + right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'Add($left, $right)';
  }
}

class Sub extends BinaryExpression {
  Sub(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '/';

  @override
  Object resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return left - right;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toString() {
    return 'Sub($left, $right)';
  }
}
