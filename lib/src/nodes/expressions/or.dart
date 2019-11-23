import '../core.dart';

class Or extends BinaryExpression {
  Or(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => 'or';

  @override
  bool resolve(Context context) => toBool(left.resolve(context)) || toBool(right.resolve(context));

  @override
  String toString() => 'Or($left, $right)';
}
