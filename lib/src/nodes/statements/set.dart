import '../../context.dart';
import '../../exceptions.dart';
import '../../runtime.dart';
import '../core.dart';

abstract class SetStatement extends Statement {
  String get target;

  String? get field;

  void assign(Context context, dynamic value) {
    if (field != null) {
      final nameSpace = context[target];

      if (nameSpace is NameSpace) {
        nameSpace[field!] = value;
        return;
      }

      throw TemplateRuntimeError('non-namespace object');
    }

    context[target] = value;
  }
}

class SetInlineStatement extends SetStatement {
  SetInlineStatement(this.target, this.value, {this.field});

  @override
  final String target;

  final Expression value;

  @override
  final String? field;

  @override
  void accept(StringSink outSink, Context context) {
    assign(context, value.resolve(context));
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('set ')
      ..write(target)
      ..write(' = ')
      ..write(value.toDebugString());
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Set($target, $value})';
  }
}

class SetBlockStatement extends SetStatement {
  SetBlockStatement(this.target, this.body, {this.field});

  @override
  final String target;

  final Node body;

  @override
  final String? field;

  @override
  void accept(StringSink outSink, Context context) {
    assign(context, body);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('set ')
      ..write(target)
      ..write(body.toDebugString(level + 1));
    return buffer.toString();

    // TODO: check: Set.toDebugString()
    // if (filter != null) {
    //   buffer.writeln(' | ${filter.toDebugString()}');
    // } else {
    //   buffer.writeln();
    // }
  }

  @override
  String toString() {
    return 'Set($target, $body})';
  }
}
