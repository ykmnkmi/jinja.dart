import '../../context.dart';
import '../../parser.dart';
import '../core.dart';
import '../expressions/filter.dart';

abstract class SetStatement extends Statement {
  static SetStatement parse(Parser parser) {
    final endsetReg = parser.getBlockEndReg('endset');

    parser.scanner.expect(Parser.nameReg);

    // TODO: namespace with field
    final target = parser.scanner.lastMatch[1];

    if (parser.scanner.scan(Parser.assignReg)) {
      if (parser.scanner.matches(parser.blockEndReg)) {
        parser.error('expression expected');
      }

      final value = parser.parseExpression(withCondition: false);

      parser.scanner.expect(parser.blockEndReg);

      return SetInlineStatement(target, value);
    }

    Filter filter;

    if (parser.scanner.matches(Parser.pipeReg)) {
      filter = parser.parseFilter(hasLeadingPipe: false);

      if (filter == null) {
        parser.error('filter expected but got ${filter.runtimeType}');
      }
    }

    parser.scanner.expect(parser.blockEndReg);

    final body = parser.parseStatements([endsetReg]);

    parser.scanner.expect(endsetReg);

    return SetBlockStatement(target, body, filter);
  }
}

class SetInlineStatement extends SetStatement {
  SetInlineStatement(this.target, this.value);

  final String target;
  final Expression value;

  @override
  void accept(_, Context context) {
    context[target] = value.resolve(context);
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'set $target = ${value.toDebugString()}';

  @override
  String toString() => 'Set($target, $value})';
}

class SetBlockStatement extends SetStatement {
  SetBlockStatement(this.target, this.body, [this.filter]);

  final String target;
  final Node body;
  final Filter filter;

  @override
  void accept(_, Context context) {
    final buffer = StringBuffer();
    body.accept(buffer, context);

    if (filter != null) {
      context[target] = filter.filter(context, buffer.toString());
    } else {
      context[target] = buffer.toString();
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('set $target');

    if (filter != null) {
      buffer.writeln(' | ${filter.toDebugString()}');
    } else {
      buffer.writeln();
    }

    buffer.write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() => 'Set($target, $body})';
}
