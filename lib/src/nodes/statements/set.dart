import '../../context.dart';
import '../../namespace.dart';
import '../core.dart';
import '../expressions/filter.dart';

abstract class SetStatement extends Statement {
  String get target;
  String get field;

  void assign(Context context, dynamic value) {
    if (field != null) {
      final nameSpace = context[target];

      if (nameSpace is NameSpace) {
        nameSpace[field] = value;
        return;
      }

      // TODO: exception
    }

    context[target] = value;
  }
}

class SetInlineStatement extends SetStatement {
  SetInlineStatement(this.target, this.value, {this.field});

  @override
  final String target;
  @override
  final String field;
  final Expression value;

  @override
  void accept(_, Context context) {
    assign(context, value.resolve(context));
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'set $target = ${value.toDebugString()}';

  @override
  String toString() => 'Set($target, $value})';
}

class SetBlockStatement extends SetStatement {
  SetBlockStatement(this.target, this.body, {this.field, this.filter});

  @override
  final String target;
  @override
  final String field;
  final Node body;
  final Filter filter;

  @override
  void accept(_, Context context) {
    final buffer = StringBuffer();
    body.accept(buffer, context);

    if (filter != null) {
      assign(context, filter.filter(context, buffer.toString()));
      return;
    }

    assign(context, buffer.toString());
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
