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
    return '${' ' * level}raw\n${' ' * (level + 1)}${repr(body)}';
  }

  @override
  String toString() {
    return 'Raw($body)';
  }
}
