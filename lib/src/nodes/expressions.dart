part of '../nodes.dart';

class Impossible implements Exception {
  Impossible();
}

abstract class Expression extends Node {
  const Expression();

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExpession(this, context);
  }

  Object? asConst(Context context) {
    throw Impossible();
  }

  Object? resolve(Context context) {
    return null;
  }
}

enum AssignContext {
  load,
  store,
  parameter,
}

abstract class Assignable extends Expression {
  bool get canAssign;

  abstract AssignContext context;
}

class Name extends Assignable {
  Name(this.name, {this.context = AssignContext.load, this.type});

  String name;

  String? type;

  @override
  AssignContext context;

  @override
  bool get canAssign {
    return context == AssignContext.store;
  }

  @override
  Expression asConst(Context context) {
    throw Impossible();
  }

  @override
  Object? resolve(Context context) {
    switch (this.context) {
      case AssignContext.load:
        return context.resolve(name);
      case AssignContext.store:
      case AssignContext.parameter:
        return name;
    }
  }

  @override
  String toString() {
    return type == null ? 'Name($name)' : 'Name($name, $type)';
  }
}

class NamespaceRef extends Expression {
  NamespaceRef(this.name, this.attribute);

  String name;

  String attribute;

  @override
  NamespaceValue resolve(Context context) {
    return NamespaceValue(name, attribute);
  }

  @override
  String toString() {
    return 'NamespaceRef($name, $attribute)';
  }
}

class Concat extends Expression {
  Concat(this.expressions);

  List<Expression> expressions;

  @override
  String resolve(Context context) {
    final buffer = StringBuffer();

    for (final expression in expressions) {
      buffer.write(expression.resolve(context));
    }

    return '$buffer';
  }

  @override
  String toString() {
    return 'Concat($expressions)';
  }
}

class Attribute extends Expression {
  Attribute(this.attribute, this.expression);

  String attribute;

  Expression expression;

  @override
  Object? resolve(Context context) {
    return context.environment
        .getAttribute(expression.resolve(context), attribute);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $expression)';
  }
}

class Item extends Expression {
  Item(this.key, this.expression);

  Expression key;

  Expression expression;

  @override
  Object? resolve(Context context) {
    return context.environment
        .getItem(key.resolve(context), expression.resolve(context));
  }

  @override
  String toString() {
    return 'Item($key, $expression)';
  }
}

class Slice extends Expression {
  factory Slice.fromList(List<Expression?> expressions) {
    assert(expressions.length <= 3);

    switch (expressions.length) {
      case 0:
        return Slice();
      case 1:
        return Slice(start: expressions[0]);
      case 2:
        return Slice(start: expressions[0], stop: expressions[1]);
      case 3:
        return Slice(
            start: expressions[0], stop: expressions[1], step: expressions[2]);
      default:
        throw TemplateRuntimeError();
    }
  }

  Slice({this.start, this.stop, this.step});

  Expression? start;

  Expression? stop;

  Expression? step;

  @override
  Iterable<int> Function(int, [int?, int?]) resolve(Context context) {
    final sliceStart = start?.resolve(context) as int?;
    final sliceStop = stop?.resolve(context) as int?;
    final sliceStep = step?.resolve(context) as int?;
    return (int stopOrStart, [int? stop, int? step]) {
      if (sliceStep == null) {
        step = 1;
      } else if (sliceStep == 0) {
        throw StateError('slice step cannot be zero');
      } else {
        step = sliceStep;
      }

      int start;

      if (sliceStart == null) {
        start = step > 0 ? 0 : stopOrStart - 1;
      } else {
        start = sliceStart < 0 ? sliceStart + stopOrStart : sliceStart;
      }

      if (sliceStop == null) {
        stop = step > 0 ? stopOrStart : -1;
      } else {
        stop = sliceStop < 0 ? sliceStop + stopOrStart : sliceStop;
      }

      return range(start, stop, step);
    };
  }

  @override
  String toString() {
    var result = 'Slice(';

    if (start != null) {
      result += 'start: $start';
    }

    if (stop != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'stop: $stop';
    }

    if (step != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'step: $step';
    }

    return result + ')';
  }
}

typedef Callback = Object? Function(List<Object?>, Map<Symbol, Object?>);

class Keyword extends Expression {
  Keyword(this.key, this.value);

  String key;

  Expression value;

  @override
  MapEntry<Symbol, Object?> resolve(Context context) {
    return MapEntry<Symbol, Object?>(Symbol(key), value.resolve(context));
  }

  Pair toPair() {
    return Pair(Constant(key), value);
  }

  @override
  String toString() {
    return 'Keyword($key, $value)';
  }
}

class Callable extends Expression {
  Callable({this.arguments, this.keywords, this.dArguments, this.dKeywords});

  List<Expression>? arguments;

  List<Keyword>? keywords;

  Expression? dArguments;

  Expression? dKeywords;

  Object? call(Context context, Callback callback) {
    final arguments = this.arguments;
    List<Object?> positional;

    if (arguments != null) {
      positional = List<Object?>.generate(
          arguments.length, (index) => arguments[index].resolve(context));
    } else {
      positional = <Object?>[];
    }

    final named = <Symbol, Object?>{};
    final keywords = this.keywords;

    if (keywords != null) {
      for (final argument in keywords) {
        named[Symbol(argument.key)] = argument.value.resolve(context);
      }
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      positional.addAll(dArguments.resolve(context) as Iterable<Object?>);
    }

    final dKeywords = this.dKeywords;

    if (dKeywords != null) {
      final resolvedKeywords = dKeywords.resolve(context);

      if (resolvedKeywords is! Map<String, Object?>) {
        // TODO: update error
        throw TypeError();
      }

      named.addAll(resolvedKeywords.map<Symbol, Object?>(
          (key, value) => MapEntry<Symbol, Object?>(Symbol(key), value)));
    }

    return callback(positional, named);
  }

  String printArguments() {
    var result = '';
    var comma = false;

    final arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result += arguments.join(', ');
    }

    final keywords = this.keywords;

    if (keywords != null && keywords.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result += keywords.join(', ');
    }

    if (dArguments != null) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result = '$result*$dArguments';
    }

    if (dKeywords != null) {
      if (comma) {
        result = '$result, ';
      }

      result = '$result**$dKeywords';
    }

    return result;
  }
}

class Call extends Callable {
  Call(
    this.expression, {
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  }) : super(
          arguments: arguments,
          keywords: keywords,
          dArguments: dArguments,
          dKeywords: dKeywords,
        );

  Expression expression;

  @override
  Object? resolve(Context context) {
    final function = expression.resolve(context);
    return call(context, (positional, named) {
      return context(function, positional, named);
    });
  }

  @override
  String toString() {
    return 'Call(${printArguments()})';
  }
}

class Filter extends Callable {
  Filter(this.name,
      {List<Expression>? arguments,
      List<Keyword>? keywords,
      Expression? dArguments,
      Expression? dKeywords})
      : super(
            arguments: arguments,
            keywords: keywords,
            dArguments: dArguments,
            dKeywords: dKeywords);

  String name;

  @override
  Object? resolve(Context context) {
    return call(context, (positional, named) {
      return context.environment.callFilter(name, positional, named);
    });
  }

  @override
  String toString() {
    return 'Filter.$name(${printArguments()})';
  }
}

class Test extends Callable {
  Test(this.name,
      {List<Expression>? arguments,
      List<Keyword>? keywords,
      Expression? dArguments,
      Expression? dKeywords})
      : super(
            arguments: arguments,
            keywords: keywords,
            dArguments: dArguments,
            dKeywords: dKeywords);

  String name;

  @override
  bool resolve(Context context) {
    return call(context, (positional, named) {
      return context.environment.callTest(name, positional, named);
    }) as bool;
  }

  @override
  String toString() {
    return 'Filter.$name(${printArguments()})';
  }
}

class Operand extends Expression {
  Operand(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  Object? resolve(Context context) {
    return expression.resolve(context);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $expression)';
  }
}

class Compare extends Expression {
  Compare(this.expression, this.operands);

  Expression expression;

  List<Operand> operands;

  @override
  Object? resolve(Context context) {
    var left = expression.resolve(context);
    var result = true;

    for (final operand in operands) {
      final right = operand.resolve(context);

      switch (operand.operator) {
        case 'eq':
          result = result && tests.isEqual(left, right);
          break;
        case 'ne':
          result = result && tests.isNotEqual(left, right);
          break;
        case 'lt':
          result = result && tests.isLessThan(left, right);
          break;
        case 'le':
          result = result && tests.isLessThanOrEqual(left, right);
          break;
        case 'gt':
          result = result && tests.isGreaterThan(left, right);
          break;
        case 'ge':
          result = result && tests.isGreaterThanOrEqual(left, right);
          break;
        case 'in':
          result = result && tests.isIn(left, right);
          break;
        case 'notin':
          result = result && !tests.isIn(left, right);
          break;
      }

      if (!result) {
        return false;
      }

      left = right;
    }

    return result;
  }

  @override
  String toString() {
    return 'Compare($expression, $operands)';
  }
}

class Condition extends Expression {
  Condition(this.test, this.expression1, [this.expression2]);

  Expression test;

  Expression expression1;

  Expression? expression2;

  @override
  Object? resolve(Context context) {
    if (boolean(test.resolve(context))) {
      return expression1.resolve(context);
    }

    return expression2?.resolve(context);
  }

  @override
  String toString() {
    return expression2 == null
        ? 'Condition($test, $expression1)'
        : 'Condition($test, $expression1, $expression2)';
  }
}

abstract class Literal extends Expression {
  @override
  String toString() {
    return 'Literal()';
  }
}

class Constant extends Literal {
  Constant(this.value);

  Object? value;

  @override
  Object? asConst(Context context) {
    return value;
  }

  @override
  Object? resolve(Context context) {
    return value;
  }

  @override
  String toString() {
    return 'Constant(${repr(value).replaceAll('\n', r'\n')})';
  }
}

class TupleLiteral extends Literal implements Assignable {
  TupleLiteral(this.expressions, [AssignContext? context])
      : context = context ?? AssignContext.load;

  @override
  AssignContext context;

  List<Expression> expressions;

  @override
  bool get canAssign {
    for (final expression in expressions) {
      if (expression is Assignable && !expression.canAssign) {
        return false;
      }
    }

    return true;
  }

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        expressions.length, (index) => expressions[index].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        expressions.length, (index) => expressions[index].resolve(context));
  }

  @override
  String toString() {
    return 'Tuple(${expressions.join(', ')})';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.expressions);

  List<Expression> expressions;

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        expressions.length, (index) => expressions[index].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        expressions.length, (index) => expressions[index].resolve(context));
  }

  @override
  String toString() {
    return 'List(${expressions.join(', ')})';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.pairs);

  List<Pair> pairs;

  @override
  Map<Object?, Object?> asConst(Context context) {
    return <Object?, Object?>{
      for (final pair in pairs)
        pair.key.asConst(context): pair.value.asConst(context)
    };
  }

  @override
  Map<Object?, Object?> resolve(Context context) {
    return <Object?, Object?>{
      for (final pair in pairs)
        pair.key.resolve(context): pair.value.resolve(context)
    };
  }

  @override
  String toString() {
    return 'Dict(${pairs.join(', ')})';
  }
}

class Unary extends Expression {
  Unary(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  Object? resolve(Context context) {
    final value = expression.resolve(context);

    switch (operator) {
      case '+':
        // how i should implement this?
        return value;
      case '-':
        return -(value as dynamic);
      case 'not':
        return !boolean(value);
    }
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $expression)';
  }
}

class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  String operator;

  Expression left;

  Expression right;

  @override
  Object? resolve(Context context) {
    final dynamic left = this.left.resolve(context);
    final dynamic right = this.right.resolve(context);

    switch (operator) {
      case '**':
        return math.pow(left as num, right as num);
      case '%':
        return left % right;
      case '//':
        return left ~/ right;
      case '/':
        return left / right;
      case '*':
        return left * right;
      case '-':
        return left - right;
      case '+':
        return left + right;
      case 'or':
        return boolean(left) ? left : right;
      case 'and':
        return boolean(left) ? right : left;
    }
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $left, $right)';
  }
}
