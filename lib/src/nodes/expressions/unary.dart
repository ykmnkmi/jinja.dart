import '../core.dart';

class Neg extends UnaryExpression {
  Neg(this.expr);

  @override
  final Expression expr;

  @override
  String get symbol => '-';

  @override
  Object resolve(Context context) {
    Object result = expr.resolve(context);

    if (result is num) return -result;

    // TODO: Neg exception message
    throw Exception();
  }

  @override
  String toDebugString([int level = 0]) => ' ' * level + '-${expr.toDebugString()}';

  @override
  String toString() => 'Neg($expr)';
}
