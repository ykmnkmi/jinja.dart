import '../core.dart';

class Neg extends UnaryExpression {
  Neg(this.expr);

  @override
  final Expression expr;

  @override
  String get symbol => '-';

  @override
  dynamic resolve(Context context) => -expr.resolve(context);

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + '-${expr.toDebugString()}';

  @override
  String toString() => 'Neg($expr)';
}
