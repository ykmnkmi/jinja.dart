import '../../exceptions.dart';
import '../core.dart';

class Call extends Expression {
  Call(this.expr, this.arguments);

  final Expression expr;

  final Arguments arguments;

  @override
  dynamic resolve(Context context) {
    final args =
        arguments.positional.map((arg) => arg.resolve(context)).toList();
    final kwargs = arguments.named
        .map((key, value) => MapEntry(Symbol(key), value.resolve(context)));

    if (arguments.positionalExpr != null) {
      final positionalExpr = arguments.positionalExpr!.resolve(context);

      if (positionalExpr is Iterable) {
        args.addAll(positionalExpr);
      } else {
        // TODO: add: error message
        throw TemplateRuntimeError();
      }
    }

    if (arguments.namedExpr != null) {
      final namedExpr = arguments.namedExpr!.resolve(context);

      if (namedExpr is Map<String, Expression>) {
        kwargs.addAll(namedExpr.map(
            (key, value) => MapEntry(Symbol(key), value.resolve(context))));
      } else {
        // TODO: add: error message
        throw TemplateRuntimeError();
      }
    }

    final dynamic resolved = expr.resolve(context);

    if (args.isEmpty && kwargs.isEmpty) {
      return resolved();
    }

    if (kwargs.isEmpty) {
      return resolved(args.length == 1 ? args[0] : args);
    }

    if (args.isEmpty) {
      return resolved(kwargs: {...kwargs});
    }

    return resolved(args, kwargs: {...kwargs});
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(expr.toDebugString(level));
    buffer.write('(');

    if (arguments.positional.isNotEmpty) {
      buffer.writeAll(
          arguments.positional.map((arg) => arg.toDebugString()), ', ');
    }

    if (arguments.positionalExpr != null) {
      if (arguments.positional.isNotEmpty || arguments.named.isNotEmpty) {
        buffer.write(', ');
      }

      buffer..write('*')..write(arguments.positionalExpr!.toDebugString());
    }

    if (arguments.named.isNotEmpty) {
      if (arguments.positional.isNotEmpty) {
        buffer.write(', ');
      }

      final pairs = arguments.named.entries
          .map((kwarg) => '${repr(kwarg.key)}: ${kwarg.value.toDebugString()}');
      buffer.writeAll(pairs, ', ');
    }

    if (arguments.namedExpr != null) {
      if (arguments.positional.isNotEmpty ||
          arguments.named.isNotEmpty ||
          arguments.positionalExpr != null) {
        buffer.write(', ');
      }

      buffer..write('**')..write(arguments.namedExpr!.toDebugString());
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('Call(');
    buffer.write(expr);

    if (arguments.positional.isNotEmpty) {
      buffer..write(', positional: ')..write(arguments.positional);
    }

    if (arguments.named.isNotEmpty) {
      buffer..write(', named: ')..write(arguments.named);
    }

    if (arguments.positionalExpr != null) {
      buffer..write(', argsDyn: ')..write(arguments.positionalExpr);
    }

    if (arguments.namedExpr != null) {
      buffer..write(', kwargsDyn: ')..write(arguments.namedExpr);
    }

    buffer.write(')');
    return buffer.toString();
  }
}

// TODO: add to filter and test, implement string
class Arguments {
  Arguments(
      {this.positional = const <Expression>[],
      this.named = const <String, Expression>{},
      this.positionalExpr,
      this.namedExpr});

  final List<Expression> positional;

  final Map<String, Expression> named;

  final Expression? positionalExpr;

  final Expression? namedExpr;
}
