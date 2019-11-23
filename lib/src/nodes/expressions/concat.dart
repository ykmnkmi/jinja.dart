import '../core.dart';

class Concat extends Expression {
  Concat(this.exprs);

  final List<Expression> exprs;

  @override
  void accept(StringBuffer buffer, Context context) {
    for (var expr in exprs) {
      expr.accept(buffer, context);
    }
  }

  @override
  String resolve(Context context) {
    StringBuffer buffer = StringBuffer();

    for (Expression expr in exprs) {
      expr.accept(buffer, context);
    }

    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + exprs.map((Expression expr) => expr.toDebugString()).join(' ~ ');

  @override
  String toString() => 'Concat($exprs)';
}
