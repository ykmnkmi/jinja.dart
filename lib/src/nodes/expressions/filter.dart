import '../core.dart';

class Filter extends Expression {
  Filter(
    this.name, {
    this.expr,
    this.args = const <Expression>[],
    this.kwargs = const <String, Expression>{},
  });

  final String name;
  final Expression expr;
  final List<Expression> args;
  final Map<String, Expression> kwargs;

  @override
  Object resolve(Context context) {
    return filter(context, expr.resolve(context));
  }

  Object filter(Context context, Object value) {
    return context.environment.callFilter(context, name,
        args: [value, ...args.map<Object>((arg) => arg.resolve(context))],
        kwargs: kwargs.map((key, value) => MapEntry(Symbol(key), value.resolve(context))));
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    if (expr != null) buffer.write('${expr.toDebugString()} | ');
    buffer.write(name);
    if (args.isEmpty && kwargs.isEmpty) return buffer.toString();

    if (args.length == 1 && kwargs.isEmpty) {
      buffer.write(' ${args[0].toDebugString()}');
      return buffer.toString();
    }

    buffer.write('(');

    if (args.isNotEmpty) {
      buffer.writeAll(args.map<String>((arg) => arg.toDebugString()), ', ');
    }

    if (kwargs.isNotEmpty) {
      if (args.isNotEmpty) buffer.write(', ');
      buffer.writeAll(
          kwargs.entries.map<String>((kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}'), ', ');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    var buffer = StringBuffer('Filter($name, $expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
