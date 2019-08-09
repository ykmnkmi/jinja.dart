import '../core.dart';

class Not extends UnaryExpression {
  Not(this.expr);

  @override
  final Expression expr;

  @override
  String get symbol => 'not ';

  @override
  bool resolve(Context context) => !toBool(expr.resolve(context));

  @override
  String toString() => 'Not($expr)';
}
