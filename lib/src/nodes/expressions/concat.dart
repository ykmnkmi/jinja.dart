import '../core.dart';

class Concat extends Expression {
  Concat(this.exprs);

  final List<Expression> exprs;

  @override
  void accept(StringBuffer buffer, Context context) {
    exprs.forEach((expr) {
      expr.accept(buffer, context);
    });
  }

  @override
  String resolve(Context context) {
    final buffer = StringBuffer();

    exprs.forEach((expr) {
      expr.accept(buffer, context);
    });

    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + exprs.map((expr) => expr.toDebugString()).join(' ~ ');

  @override
  String toString() => 'Concat($exprs)';
}
