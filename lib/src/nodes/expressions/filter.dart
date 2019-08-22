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
  dynamic resolve(Context context) => filter(context, expr.resolve(context));

  dynamic filter(Context context, Object value) => context.env.callFilter(
        name,
        args: [value]
            .followedBy(args.map((arg) => arg.resolve(context)))
            .toList(growable: false),
        kwargs: kwargs.map((key, value) =>
            MapEntry<Symbol, dynamic>(Symbol(key), value.resolve(context))),
      );

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
      buffer.write(args.map((arg) => arg.toDebugString()).join(', '));
    }

    if (kwargs.isNotEmpty) {
      if (args.isNotEmpty) buffer.write(', ');
      buffer.write(kwargs.entries
          .map((kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}')
          .join(', '));
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('Filter($name, $expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
