import '../../context.dart';
import '../../parser.dart';
import '../core.dart';

class IfStatement extends Statement {
  static IfStatement parse(Parser parser) {
    final elseReg = parser.getBlockEndRegFor('else');
    final endIfReg = parser.getBlockEndRegFor('endif');

    final pairs = <Expression, Node>{};
    Node orElse;

    while (true) {
      if (parser.scanner.matches(parser.blockEndReg)) {
        parser.error('expect statement body');
      }

      final condition = parser.parseExpression();

      parser.scanner.expect(parser.blockEndReg);

      final body = parser.parseStatements(['elif', elseReg, endIfReg]);

      if (parser.scanner.scan('elif')) {
        parser.scanner.scan(Parser.spaceReg);
        pairs[condition] = body;
        continue;
      } else if (parser.scanner.scan(elseReg)) {
        pairs[condition] = body;
        orElse = parser.parseStatements([endIfReg]);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    parser.scanner.expect(endIfReg);

    return IfStatement(pairs, orElse);
  }

  IfStatement(this.pairs, [this.orElse]);

  final Map<Expression, Node> pairs;
  final Node orElse;

  @override
  void accept(StringBuffer buffer, Context context) {
    for (var pair in pairs.entries) {
      if (toBool(pair.key.resolve(context))) {
        pair.value.accept(buffer, context);
        return;
      }
    }

    orElse?.accept(buffer, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    final first = pairs.entries.first;
    buffer.writeln('if ${first.key.toDebugString()}');
    buffer.write(first.value.toDebugString(level + 1));

    for (var pair in pairs.entries.skip(1)) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('if ${pair.key.toDebugString()}');
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
    final buffer = StringBuffer('If($pairs');
    if (orElse != null) buffer.write(', $orElse');
    buffer.write(')');
    return buffer.toString();
  }
}
