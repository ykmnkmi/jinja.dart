import '../../context.dart';
import '../core.dart';
import '../expressions/filter.dart';

abstract class SetStatement extends Statement {}

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
