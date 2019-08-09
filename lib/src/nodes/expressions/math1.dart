import '../core.dart';

class Add extends BinaryExpression {
  Add(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '+';

  @override
  dynamic resolve(Context context) =>
      left.resolve(context) + right.resolve(context);

  @override
  String toString() => 'Add($left, $right)';
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
  dynamic resolve(Context context) =>
      left.resolve(context) - right.resolve(context);

  @override
  String toString() => 'Sub($left, $right)';
}
