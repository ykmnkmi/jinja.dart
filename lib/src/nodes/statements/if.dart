import '../../context.dart';
import '../core.dart';

class IfStatement extends Statement {
  IfStatement(this.pairs, [this.orElse]);

  final Map<Expression, Node> pairs;

  final Node? orElse;

  @override
  void accept(StringSink outSink, Context context) {
    for (final pair in pairs.entries) {
      if (toBool(pair.key.resolve(context))) {
        pair.value.accept(outSink, context);
        return;
      }
    }

    orElse?.accept(outSink, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    final first = pairs.entries.first;

    buffer
      ..write('if ')
      ..writeln(first.key.toDebugString())
      ..write(first.value.toDebugString(level + 1));

    for (final pair in pairs.entries.skip(1)) {
      buffer
        ..writeln()
        ..write(' ' * level)
        ..write('if ')
        ..writeln(pair.key.toDebugString())
        ..write(pair.value.toDebugString(level + 1));
    }

    if (orElse != null) {
      buffer
        ..writeln()
        ..write(' ' * level)
        ..writeln('else')
        ..write(orElse!.toDebugString(level + 1));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('If(');
    buffer.write(pairs);

    if (orElse != null) {
      buffer..write(', ')..write(orElse);
    }

    buffer.write(')');
    return buffer.toString();
  }
}
