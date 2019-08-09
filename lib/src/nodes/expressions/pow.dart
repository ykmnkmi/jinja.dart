import 'dart:math';

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
  dynamic resolve(Context context) =>
      // ignore: argument_type_not_assignable
      pow(left.resolve(context), right.resolve(context));

  @override
  String toString() => 'Pow($left, $right)';
}
