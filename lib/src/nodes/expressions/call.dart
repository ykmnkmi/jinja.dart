import 'dart:mirrors';

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
  dynamic resolve(Context context) {
    var args =
        this.args.map((arg) => arg.resolve(context)).toList(growable: false);
    var kwargs = this
        .kwargs
        .map((key, value) => MapEntry(Symbol(key), value.resolve(context)));

    if (this.argsDyn != null) {
      final argsDyn = this.argsDyn.resolve(context);

      if (argsDyn is Iterable) {
        args = args.followedBy(argsDyn).toList(growable: false);
      } else {
        throw Exception();
      }
    }

    if (kwargsDyn != null) {
      final kwargsDyn = this.kwargsDyn.resolve(context);

      if (kwargsDyn is Map<String, dynamic>) {
        kwargs.addAll(kwargsDyn.map(
            (key, value) => MapEntry(Symbol(key), value.resolve(context))));
      } else {
        throw Exception();
      }
    }

    return reflect(expr.resolve(context)).invoke(#call, args, kwargs).reflectee;
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(expr.toDebugString(level));
    buffer.write('(');

    if (args.isNotEmpty) {
      buffer.write(args.map((arg) => arg.toDebugString()).join(', '));
    }

    if (argsDyn != null) {
      if (args.isNotEmpty || kwargs.isNotEmpty) buffer.write(', ');
      buffer.write('*${argsDyn.toDebugString()}');
    }

    if (kwargs.isNotEmpty) {
      if (args.isNotEmpty) buffer.write(', ');
      buffer.write(kwargs.entries
          .map((kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}')
          .join(', '));
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
    final buffer = StringBuffer('Call($expr');
    if (args != null && args.isNotEmpty) buffer.write(', args: $args');
    if (kwargs != null && kwargs.isNotEmpty) buffer.write(', kwargs: $kwargs');
    buffer.write(')');
    return buffer.toString();
  }
}
