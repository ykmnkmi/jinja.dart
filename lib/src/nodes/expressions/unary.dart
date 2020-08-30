import '../core.dart';

class Neg extends UnaryExpression {
  Neg(this.expr) : symbol = '-';

  @override
  final Expression expr;

  @override
  final String symbol;

  @override
  dynamic resolve(Context context) {
    final result = expr.resolve(context);

    if (result is num) {
      return -result;
    }

    // TODO: add: error message
    throw Exception();
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('-')
      ..write(expr.toDebugString());
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Neg($expr)';
  }
}
