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
    return context.env.callFilter(name,
        args: <Object>[value]
            .followedBy(
                args.map<Object>((Expression arg) => arg.resolve(context)))
            .toList(),
        kwargs: kwargs.map<Symbol, Object>((String key, Expression value) =>
            MapEntry<Symbol, Object>(Symbol(key), value.resolve(context))));
  }

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer(' ' * level);
    if (expr != null) buffer.write('${expr.toDebugString()} | ');
    buffer.write(name);
    if (args.isEmpty && kwargs.isEmpty) return buffer.toString();

    if (args.length == 1 && kwargs.isEmpty) {
      buffer.write(' ${args[0].toDebugString()}');
      return buffer.toString();
    }

    buffer.write('(');

    if (args.isNotEmpty) {
      buffer.writeAll(
          args.map<String>((Expression arg) => arg.toDebugString()), ', ');
    }

    if (kwargs.isNotEmpty) {
      if (args.isNotEmpty) buffer.write(', ');
      buffer.writeAll(
          kwargs.entries.map<String>((MapEntry<String, Expression> kwarg) =>
              '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}'),
          ', ');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer('Filter($name, $expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
