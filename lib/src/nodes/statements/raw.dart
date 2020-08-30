import '../core.dart';

class RawStatement extends Statement {
  RawStatement(this.body);

  final String body;

  @override
  void accept(StringSink outSink, Context context) {
    outSink.write(body);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..writeln('raw')
      ..write(' ' * (level + 1))
      ..write(repr(body));
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Raw($body)';
  }
}
