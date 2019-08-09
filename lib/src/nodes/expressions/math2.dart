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
  dynamic resolve(Context context) =>
      left.resolve(context) * right.resolve(context);

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
  dynamic resolve(Context context) =>
      left.resolve(context) / right.resolve(context);

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
  dynamic resolve(Context context) =>
      left.resolve(context) ~/ right.resolve(context);

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
  dynamic resolve(Context context) =>
      left.resolve(context) % right.resolve(context);

  @override
  String toString() => 'Mod($left, $right)';
}
