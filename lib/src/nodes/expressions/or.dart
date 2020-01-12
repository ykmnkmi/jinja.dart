import '../core.dart';

class Or extends BinaryExpression {
  Or(this.left, this.right) : symbol = 'or';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    return toBool(left.resolve(context)) || toBool(right.resolve(context));
  }

  @override
  String toString() {
    return 'Or($left, $right)';
  }
}
