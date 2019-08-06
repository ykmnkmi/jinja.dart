import 'dart:math' as math;
import 'dart:mirrors';

import 'context.dart';
import 'tests.dart';
import 'utils.dart';

abstract class Node {
  const Node();

  String render(Context context) => '';

  @override
  String toString() => 'Node()';
}

// Nodes

class Output extends Node {
  static Node orNode(List<Node> nodes) {
    if (nodes.isEmpty) return const Literal<String>('');
    return nodes.length > 1 ? Output(nodes) : nodes.first;
  }

  const Output(this.nodes);

  final List<Node> nodes;

  @override
  String render(Context context) =>
      nodes.map((node) => node.render(context)).join();

  @override
  String toString() => 'Output($nodes)';
}

abstract class Expression extends Node {
  const Expression();

  call(Context context);

  @override
  String render(Context context) => '${context.env.finalize(call(context))}';
}

class ExpressionList extends Expression {
  const ExpressionList(this.values);
  ExpressionList.of(Iterable<Expression> values)
      : values = List<Expression>.of(values, growable: false);

  final List<Expression> values;

  @override
  List call(Context context) =>
      values.map((value) => value(context)).toList(growable: false);

  @override
  String toString() => 'ExpressionList($values)';
}

class ExpressionMap extends Expression {
  const ExpressionMap(this.values);
  ExpressionMap.of(Map<String, Expression> values)
      : values = Map<String, Expression>.of(values);

  final Map<String, Expression> values;

  @override
  Map<String, dynamic> call(Context context) => values
      .map((key, value) => MapEntry<String, dynamic>(key, value(context)));

  @override
  String toString() => 'ExpressionMap($values)';
}

class Literal<T> extends Expression {
  const Literal(this.value);

  final T value;

  @override
  T call(_) => value;

  @override
  String toString() => rprint('Literal<$T>($value)');
}

class Variable extends Expression {
  const Variable(this.name);

  final String name;

  @override
  call(Context context) => context.get(name);

  @override
  String toString() => 'Variable($name)';
}

class Key extends Expression {
  const Key(this.key, this.expr);

  final Expression key;
  final Expression expr;

  @override
  call(Context context) => expr(context)[key(context)];

  @override
  String toString() => 'Key($key, $expr)';
}

class Field extends Expression {
  const Field(this.field, this.expr);

  final String field;
  final Expression expr;

  @override
  call(Context context) => getAttr(expr(context), field);

  @override
  String toString() => 'Field($field, $expr)';
}

class Not extends Expression {
  const Not(this.expr);

  final Expression expr;

  @override
  call(Context context) => !asBool(expr(context));

  @override
  String toString() => 'Not($expr)';
}

class Neg extends Expression {
  const Neg(this.expr);

  final Expression expr;

  @override
  call(Context context) => -expr(context);

  @override
  String toString() => 'Neg($expr)';
}

class Pos extends Expression {
  const Pos(this.expr);

  final Expression expr;

  @override
  call(Context context) => expr(context);

  @override
  String toString() => 'Pos($expr)';
}

class Mul extends Expression {
  const Mul(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) * right(context);

  @override
  String toString() => 'Mul($left, $right)';
}

class Div extends Expression {
  const Div(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) / right(context);

  @override
  String toString() => 'Div($left, $right)';
}

class FloorDiv extends Expression {
  const FloorDiv(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) ~/ right(context);

  @override
  String toString() => 'FloorDiv($left, $right)';
}

class Mod extends Expression {
  const Mod(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) % right(context);

  @override
  String toString() => 'Mod($left, $right)';
}

class Pow extends Expression {
  const Pow(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => math.pow(left(context), right(context));

  @override
  String toString() => 'Pow($left, $right)';
}

class Add extends Expression {
  const Add(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) + right(context);

  @override
  String toString() => 'Add($left, $right)';
}

class Sub extends Expression {
  const Sub(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => left(context) - right(context);

  @override
  String toString() => 'Sub($left, $right)';
}

class GreaterOrEqual extends Expression {
  const GreaterOrEqual(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => ge(left(context), right(context));

  @override
  String toString() => 'GreaterOrEqual($left, $right)';
}

class Greater extends Expression {
  const Greater(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => gt(left(context), right(context));

  @override
  String toString() => 'Greater($left, $right)';
}

class Less extends Expression {
  const Less(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => lt(left(context), right(context));

  @override
  String toString() => 'Less($left, $right)';
}

class LessOrEqual extends Expression {
  const LessOrEqual(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => le(left(context), right(context));

  @override
  String toString() => 'LessOrEqual($left, $right)';
}

class Equal extends Expression {
  const Equal(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => eq(left(context), right(context));

  @override
  String toString() => 'Equal($left, $right)';
}

class NotEqual extends Expression {
  const NotEqual(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) => ne(left(context), right(context));

  @override
  String toString() => 'NotEqual($left, $right)';
}

class And extends Expression {
  const And(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) {
    final leftRes = left(context);
    return asBool(leftRes) ? right(context) : leftRes;
  }

  @override
  String toString() => 'And($left, $right)';
}

class Or extends Expression {
  const Or(this.left, this.right);

  final Expression left;
  final Expression right;

  @override
  call(Context context) {
    final leftRes = left(context);
    return asBool(leftRes) ? leftRes : right(context);
  }

  @override
  String toString() => 'Or($left, $right)';
}

// class Conditional extends Expression {
//   const Conditional(this.expr, this.condition, this.orElse);

//   final Expression expr;
//   final Expression condition;
//   final Expression orElse;

//   dynamic call(Context context) =>
//       asBool(condition(context)) ? expr(context) : orElse(context);

//   @override
//   String toString() => rprint('Conditional($expr, $condition, $orElse)';
// }

class Call extends Expression {
  const Call(this.expr, {this.args = const [], this.kwargs = const {}});

  final Expression expr;
  final List<Expression> args;
  final Map<String, Expression> kwargs;

  @override
  call(Context context) => reflect(expr(context))
      .invoke(
          Symbol('call'),
          args.map((arg) => arg(context)).toList(growable: false),
          kwargs.map((key, expr) => MapEntry(Symbol(key), expr(context))))
      .reflectee;

  @override
  String toString() => 'Call($expr'
      '${args.isNotEmpty ? ', args: ' + args.toString() : ''}'
      '${kwargs.isNotEmpty ? ', kwargs: ' + kwargs.toString() : ''})';
}

class CallSpread extends Expression {
  const CallSpread(this.expr, this.variable);

  final Expression expr;
  final Expression variable;

  @override
  dynamic call(Context context) => reflect(expr(context))
      .invoke(Symbol('call'), variable(context))
      .reflectee;

  @override
  String toString() => 'CallSpread($expr, $variable)';
}

class Filter extends Expression {
  const Filter(this.name, this.expr,
      {this.args = const [], this.kwargs = const {}});

  final String name;
  final Expression expr;
  final List<Expression> args;
  final Map<String, Expression> kwargs;

  @override
  call(Context context) => context.env.callFilter(
      name,
      [expr(context)]
          .followedBy(args.map((arg) => arg(context)))
          .toList(growable: false),
      kwargs.map((key, expr) => MapEntry(Symbol(key), expr(context))));

  @override
  String toString() => 'Filter($name, $expr'
      '${args.isNotEmpty ? ', args: ' + args.toString() : ''}'
      '${kwargs.isNotEmpty ? ', kwargs: ' + kwargs.toString() : ''})';
}

class Test extends Expression {
  const Test(this.name, this.expr,
      {this.args = const [], this.kwargs = const {}});

  final String name;
  final Expression expr;
  final List<Expression> args;
  final Map<String, Expression> kwargs;

  @override
  call(Context context) => context.env.callTest(
      name,
      [expr(context)]
          .followedBy(args.map((arg) => arg(context)))
          .toList(growable: false),
      kwargs.map((key, expr) =>
          MapEntry<Symbol, dynamic>(Symbol(key), expr(context))));

  @override
  String toString() => 'Test($name, $expr'
      '${args.isNotEmpty ? ', args: ' + args.toString() : ''}'
      '${kwargs.isNotEmpty ? ', kwargs' + kwargs.toString() : ''})';
}

// Statements

class Extend extends Node {
  const Extend(this.parent, this.blocks);

  final Expression parent;
  final Map<String, Block> blocks;

  @override
  String render(Context context) {
    final extendContext = context.copyWith(blocks: blocks);
    final parentPath = parent(extendContext).toString();
    return context.env.callTemplateWithContext(parentPath, extendContext);
  }

  @override
  String toString() => 'Extend($parent, $blocks)';
}

class Block extends Node {
  const Block(this.name, this.body);

  final String name;
  final Node body;

  @override
  String render(Context context) {
    if (context.blocks.containsKey(name)) {
      final blockContext =
          context.copyWith(data: {'super': () => body.render(context)});
      return context.blocks[name].body.render(blockContext);
    }
    return body.render(context);
  }

  @override
  String toString() => 'Block($name, $body)';
}

class For extends Node {
  const For(this.target, this.iter, this.body,
      {this.isRecursive, this.test, this.orElse});

  final String target;
  final Expression iter;
  final Node body;
  final bool isRecursive;
  final Test test;
  final Node orElse;

  @override
  String render(Context context) {
    final iter = this.iter(context);

    if (iter is Iterable && iter.isNotEmpty) {
      final list = iter.toList(growable: false);
      final buffer = StringBuffer();

      var prevItem;
      bool changed(newitem) {
        final isChanged = prevItem != newitem;
        prevItem = newitem;
        return isChanged;
      }

      LoopContext loopContext;
      final check = test != null ? test as Function : (Context context) => true;
      for (var i = 0; i < list.length; i++) {
        if (isRecursive) {
          loopContext = RecursiveLoopContext(
              (value) => For(target, Literal(value), body,
                      isRecursive: isRecursive, test: test, orElse: orElse)
                  .render(context),
              list.length,
              i,
              i > 0 ? list[i - 1] : context.env.undefined,
              i < list.length - 1 ? list[i + 1] : context.env.undefined,
              changed);
        } else {
          loopContext = LoopContext(
              list.length,
              i,
              i > 0 ? list[i - 1] : context.env.undefined,
              i < list.length - 1 ? list[i + 1] : context.env.undefined,
              changed);
        }

        context = context.copyWith(data: {
          target: list[i],
          'loop': loopContext,
        });

        if (check(context)) buffer.write(body.render(context));
      }

      return buffer.toString();
    }

    if (orElse != null) return orElse.render(context);
    throw ArgumentError();
  }

  @override
  String toString() => 'For($target, $iter, $body'
      '${isRecursive ? ', isRecursive: ' + isRecursive.toString() : ''}'
      '${test != null ? ', test: ' + test.toString() : ''}'
      '${orElse != null ? ', orElse: ' + orElse.toString() : ''})';
}

class If extends Node {
  const If(this.test, this.body, [this.orElse]);

  final Test test;
  final Node body;
  final Node orElse;

  @override
  String render(Context context) =>
      test(context) ? body.render(context) : orElse?.render(context) ?? '';

  @override
  String toString() => 'If($test, $body'
      '${orElse != null ? ', ' + orElse.toString() : ''})';
}

class Set extends Node {
  const Set(this.name, this.variable);

  final String name;
  final Expression variable;

  @override
  String render(Context context) {
    context.data[name] = variable(context);
    return '';
  }

  @override
  String toString() => 'Set($name, $variable)';
}

// Helpers

class Tag extends Node {
  const Tag(this.tag, [this.arg, this.arg2, this.arg3, this.arg4]);

  final String tag;
  final arg;
  final arg2;
  final arg3;
  final arg4;

  @override
  String toString() => 'Tag($tag)';
}
