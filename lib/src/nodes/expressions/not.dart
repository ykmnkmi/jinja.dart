import '../core.dart';

class Not extends UnaryExpression {
  Not(this.expr) : symbol = 'not ';

  @override
  final Expression expr;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    return !toBool(expr.resolve(context));
  }

  @override
  String toString() {
    return 'Not($expr)';
  }
}
