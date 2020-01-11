import '../../context.dart';
import '../core.dart';

class IfStatement extends Statement {
  IfStatement(this.pairs, [this.orElse]);

  final Map<Expression, Node> pairs;
  final Node orElse;

  @override
  void accept(StringSink outSink, Context context) {
    for (MapEntry<Expression, Node> pair in pairs.entries) {
      if (toBool(pair.key.resolve(context))) {
        pair.value.accept(outSink, context);
        return;
      }
    }

    orElse?.accept(outSink, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final StringBuffer buffer = StringBuffer(' ' * level);
    final MapEntry<Expression, Node> first = pairs.entries.first;
    buffer.writeln('if ' + first.key.toDebugString());
    buffer.write(first.value.toDebugString(level + 1));

    for (MapEntry<Expression, Node> pair in pairs.entries.skip(1)) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('if ' + pair.key.toDebugString());
      buffer.write(pair.value.toDebugString(level + 1));
    }

    if (orElse != null) {
      buffer.writeln();
      buffer.writeln(' ' * level + 'else');
      buffer.write(orElse.toDebugString(level + 1));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('If($pairs');

    if (orElse != null) {
      buffer.write(', $orElse');
    }

    buffer.write(')');
    return buffer.toString();
  }
}
