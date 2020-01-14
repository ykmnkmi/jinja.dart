import '../core.dart';

class And extends BinaryExpression {
  And(this.left, this.right) : symbol = 'and';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final symbol;

  @override
  bool resolve(Context context) {
    return toBool(left.resolve(context)) && toBool(right.resolve(context));
  }

  @override
  String toString() {
    return 'And($left, $right)';
  }
}
