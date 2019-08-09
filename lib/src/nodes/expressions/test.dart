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

  bool test(Context context, dynamic value) =>
      context.environment.callTest(name,
          args: [value]
              .followedBy(args.map((arg) => arg.resolve(context)))
              .toList(growable: false),
          kwargs: kwargs.map((key, value) =>
              MapEntry<Symbol, dynamic>(Symbol(key), value.resolve(context))));

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
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
    final buffer = StringBuffer('Test($name');
    if (expr != null) buffer.write(', $expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
