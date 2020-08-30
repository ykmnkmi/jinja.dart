import 'dart:math' show pow;

import '../core.dart';

class Pow extends BinaryExpression {
  Pow(this.left, this.right) : symbol = '**';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  dynamic resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is num && right is num) {
      return pow(left, right);
    }

    // TODO: add: error message
    throw Exception();
  }

  @override
  String toString() {
    return 'Pow($left, $right)';
  }
}
