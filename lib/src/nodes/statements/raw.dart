import '../core.dart';

class RawStatement extends Statement {
  RawStatement(this.body);

  final String body;

  @override
  void accept(StringBuffer buffer, _) {
    buffer.write(body);
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'raw\n' + ' ' * (level + 1) + repr(body);

  @override
  String toString() => 'Raw($body)';
}
