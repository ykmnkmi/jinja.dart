import '../../parser.dart';
import '../core.dart';

class RawStatement extends Statement {
  static RawStatement parse(Parser parser) {
    final endRawReg = parser.getBlockEndRegFor('endraw', true);
    parser.scanner.expect(Parser.getBlockEndReg(parser.env.blockEnd));
    final start = parser.scanner.state;
    var end = start;

    while (!parser.scanner.isDone && !parser.scanner.scan(endRawReg)) {
      parser.scanner.readChar();
      end = parser.scanner.state;
    }

    return RawStatement(parser.scanner.spanFrom(start, end).text);
  }

  RawStatement(this.body);

  final String body;

  @override
  void accept(StringBuffer buffer, _) {
    buffer.write(body);
  }

  @override
  String toDebugString([int level = 0]) =>
      '${' ' * level}raw\n${' ' * (level + 1) + repr(body)}';

  @override
  String toString() => 'Raw($body)';
}
