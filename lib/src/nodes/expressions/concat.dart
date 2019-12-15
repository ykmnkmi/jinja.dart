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
    final StringBuffer buffer = StringBuffer();

    for (final expr in exprs) {
      expr.accept(buffer, context);
    }

    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) {
    final StringBuffer buffer = StringBuffer(' ' * level);
    buffer.writeAll(exprs.map<String>((expr) => expr.toDebugString()), ' ~ ');
    return '$buffer';
  }

  @override
  String toString() => 'Concat($exprs)';
}
