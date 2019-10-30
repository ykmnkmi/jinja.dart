import '../core.dart';

class Test extends Expression {
  Test(
    this.name, {
    this.expr,
    this.args = const <Expression>[],
    this.kwargs = const <String, Expression>{},
  });

  final Expression expr;
  final String name;
  final List<Expression> args;
  final Map<String, Expression> kwargs;

  @override
  bool resolve(Context context) => test(context, expr.resolve(context));

  bool test(Context context, Object value) => context.env.callTest(name,
      args: <Object>[
        value,
        ...args.map<Object>((Expression arg) => arg.resolve(context))
      ],
      kwargs: kwargs.map((String key, Expression value) =>
          MapEntry<Symbol, Object>(Symbol(key), value.resolve(context))));

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer(' ' * level);
    if (expr != null) buffer.write(expr.toDebugString());
    if (name == 'defined') return buffer.toString();
    buffer.write(' is $name');
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
    StringBuffer buffer = StringBuffer('Test($name');
    if (expr != null) buffer.write(', $expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
