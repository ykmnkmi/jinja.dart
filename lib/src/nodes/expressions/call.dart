import '../../exceptions.dart';
import '../core.dart';

class Call extends Expression {
  Call(
    this.expr, {
    this.args = const <Expression>[],
    this.kwargs = const <String, Expression>{},
    this.argsDyn,
    this.kwargsDyn,
  });

  final Expression expr;
  final List<Expression> args;
  final Map<String, Expression> kwargs;
  final Expression argsDyn;
  final Expression kwargsDyn;

  @override
  Object resolve(Context context) {
    final List<Object> args = this.args.map<Object>((Expression arg) => arg.resolve(context)).toList();
    final Map<Symbol, Object> kwargs = this.kwargs.map<Symbol, Object>(
        (String key, Expression value) => MapEntry<Symbol, Object>(Symbol(key), value.resolve(context)));

    if (argsDyn != null) {
      final Object argsDyn = this.argsDyn.resolve(context);

      if (argsDyn is Iterable<Object>) {
        args.addAll(argsDyn);
      } else {
        // TODO: добавить: текст ошибки
        throw TemplateRuntimeError();
      }
    }

    if (kwargsDyn != null) {
      final Object kwargsDyn = this.kwargsDyn.resolve(context);

      if (kwargsDyn is Map<String, Expression>) {
        kwargs.addAll(kwargsDyn.map<Symbol, Object>(
            (String key, Expression value) => MapEntry<Symbol, Object>(Symbol(key), value.resolve(context))));
      } else {
        // TODO: добавить: текст ошибки
        throw TemplateRuntimeError();
      }
    }

    return Function.apply(expr.resolve(context) as Function, args, kwargs);
  }

  @override
  String toDebugString([int level = 0]) {
    final StringBuffer buffer = StringBuffer(expr.toDebugString(level));
    buffer.write('(');

    if (args.isNotEmpty) {
      buffer.writeAll(args.map<String>((Expression arg) => arg.toDebugString()), ', ');
    }

    if (argsDyn != null) {
      if (args.isNotEmpty || kwargs.isNotEmpty) buffer.write(', ');
      buffer.write('*${argsDyn.toDebugString()}');
    }

    if (kwargs.isNotEmpty) {
      if (args.isNotEmpty) buffer.write(', ');
      buffer.writeAll(
          kwargs.entries.map<String>(
              (MapEntry<String, Expression> kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}'),
          ', ');
    }

    if (kwargsDyn != null) {
      if (args.isNotEmpty || kwargs.isNotEmpty || argsDyn != null) {
        buffer.write(', ');
      }

      buffer.write('**${kwargsDyn.toDebugString()}');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('Call($expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    if (argsDyn != null) buffer.write(', argsDyn: $argsDyn');
    if (kwargsDyn != null) buffer.write(', kwargsDyn: $kwargsDyn');
    buffer.write(')');
    return buffer.toString();
  }
}
