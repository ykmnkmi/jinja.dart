import '../core.dart';

class Concat extends Expression {
  Concat(this.exprs);

  final List<Expression> exprs;

  @override
  void accept(StringSink outSink, Context context) {
    for (final expr in exprs) {
      expr.accept(outSink, context);
    }
  }

  @override
  String resolve(Context context) {
    final buffer = StringBuffer();

    for (final expr in exprs) {
      expr.accept(buffer, context);
    }

    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..writeAll(exprs.map((expr) => expr.toDebugString()), ' ~ ');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Concat($exprs)';
  }
}
