import 'dart:math' show pow;

import '../core.dart';

class Pow extends BinaryExpression {
  Pow(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '**';

  @override
  Object resolve(Context context) {
    final Object left = this.left.resolve(context);
    final Object right = this.right.resolve(context);

    if (left is num && right is num) return pow(left, right);

    // TODO: исправить
    throw Exception();
  }

  @override
  String toString() => 'Pow($left, $right)';
}
