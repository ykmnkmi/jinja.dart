import '../core.dart';

class Neg extends UnaryExpression {
  Neg(this.expr) : symbol = '-';

  @override
  final Expression expr;

  @override
  final symbol;

  @override
  Object resolve(Context context) {
    final result = expr.resolve(context);

    if (result is num) {
      return -result;
    }

    // TODO: добавить: текст ошибки
    throw Exception();
  }

  @override
  String toDebugString([int level = 0]) {
    return '${' ' * level}-${expr.toDebugString()}';
  }

  @override
  String toString() {
    return 'Neg($expr)';
  }
}
