import '../core.dart';

class Filter extends Expression {
  Filter(this.name,
      {this.expr,
      this.positional = const <Expression>[],
      this.named = const <String, Expression>{}});

  final String name;

  final Expression? expr;

  final List<Expression> positional;

  final Map<String, Expression> named;

  @override
  Object? resolve(Context context) {
    return filter(context, expr?.resolve(context));
  }

  Object? filter(Context context, Object? value) {
    return context.environment.callFilter(context, name,
        positional: [value, ...positional.map((arg) => arg.resolve(context))],
        named: named.map(
            (key, value) => MapEntry(Symbol(key), value.resolve(context))));
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);

    if (expr != null) {
      buffer..write(expr!.toDebugString())..write(' | ');
    }

    buffer.write(name);

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
    final buffer = StringBuffer('Filter(');
    buffer..write(name)..write(', ')..write(expr);

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
