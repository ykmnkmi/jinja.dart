import '../core.dart';

class And extends BinaryExpression {
  And(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => 'and';

  @override
  bool resolve(Context context) =>
      toBool(left.resolve(context)) && toBool(right.resolve(context));

  @override
  String toString() => 'And($left, $right)';
}
