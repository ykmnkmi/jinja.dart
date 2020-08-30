import '../core.dart';

class Test extends Expression {
  Test(this.name,
      {this.expr,
      this.positional = const <Expression>[],
      this.named = const <String, Expression>{}});

  final Expression? expr;

  final String name;

  final List<Expression> positional;

  final Map<String, Expression> named;

  @override
  bool resolve(Context context) {
    return test(context, expr?.resolve(context));
  }

  bool test(Context context, dynamic value) {
    return context.environment.callTest(name,
        positional: [value, ...positional.map((arg) => arg.resolve(context))],
        named: named.map(
            (key, value) => MapEntry(Symbol(key), value.resolve(context))));
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);

    if (expr != null) {
      buffer.write(expr!.toDebugString());
    }

    if (name == 'defined') {
      return buffer.toString();
    }

    buffer..write(' is ')..write(name);

    if (positional.isEmpty && named.isEmpty) {
      return buffer.toString();
    }

    if (positional.length == 1 && named.isEmpty) {
      buffer..write(' ')..write(positional[0].toDebugString());
      return buffer.toString();
    }

    buffer.write('(');

    if (positional.isNotEmpty) {
      buffer.writeAll(positional.map((arg) => arg.toDebugString()), ', ');
    }

    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        buffer.write(', ');
      }

      final pairs = named.entries
          .map((kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}');
      buffer.writeAll(pairs, ', ');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('Test(');
    buffer.write(name);

    if (expr != null) {
      buffer..write(', ')..write(expr);
    }

    if (positional.isNotEmpty) {
      buffer..write(', positional: ')..write(positional);
    }

    if (named.isNotEmpty) {
      buffer..write(', named: ')..write(named);
    }

    buffer.write(')');
    return buffer.toString();
  }
}
