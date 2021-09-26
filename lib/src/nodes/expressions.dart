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
  Name(this.name, {this.context = AssignContext.load});

  String name;

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
    return context == AssignContext.load
        ? 'Name($name)'
        : 'Name($name, $context)';
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
  void visitChildrens(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'Concat(${expressions.join(', ')})';
  }
}

class Attribute extends Expression {
  Attribute(this.attribute, this.value);

  String attribute;

  Expression value;

  @override
  Object? resolve(Context context) {
    final value = this.value.resolve(context);
    return context.environment.getAttribute(value, attribute);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    value.apply(visitor);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $value)';
  }
}

class Item extends Expression {
  Item(this.key, this.value);

  Expression key;

  Expression value;

  @override
  Object? resolve(Context context) {
    final key = this.key.resolve(context);
    final value = this.value.resolve(context);
    return context.environment.getItem(value, key);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    key.apply(visitor);
    value.apply(visitor);
  }

  @override
  String toString() {
    return 'Item($key, $value)';
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

  @override
  void visitChildrens(NodeVisitor visitor) {
    value.apply(visitor);
  }

  MapEntry<Expression, Expression> toMapEntry() {
    return MapEntry<Expression, Expression>(Constant(key), value);
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

  T call<T extends Object?>(Context context, Callback callback) {
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

      if (resolvedKeywords is! Map) {
        throw TypeError();
      }

      named.addAll(resolvedKeywords
          .cast<String, Object?>()
          .map<Symbol, Object?>(
              (key, value) => MapEntry<Symbol, Object?>(Symbol(key), value)));
    }

    return callback(positional, named) as T;
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    arguments?.forEach(visitor);
    keywords?.forEach(visitor);
    dArguments?.apply(visitor);
    dKeywords?.apply(visitor);
  }

  String printArguments({bool comma = false}) {
    var result = '';
    final arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result = '$result${arguments.join(', ')}';
    }

    final keywords = this.keywords;

    if (keywords != null && keywords.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result = '$result${keywords.join(', ')}';
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
  Call(this.expression,
      {List<Expression>? arguments,
      List<Keyword>? keywords,
      Expression? dArguments,
      Expression? dKeywords})
      : super(
            arguments: arguments,
            keywords: keywords,
            dArguments: dArguments,
            dKeywords: dKeywords);

  Expression expression;

  @override
  Object? resolve(Context context) {
    final function = expression.resolve(context);
    return call(context, (positional, named) {
      return context(function, positional, named);
    });
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    expression.apply(visitor);
    super.visitChildrens(visitor);
  }

  @override
  String toString() {
    return 'Call($expression${printArguments(comma: true)})';
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
      return context.environment.callFilter(name, positional, named, context);
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
    return call<bool>(context, (positional, named) {
      return context.environment.callTest(name, positional, named);
    });
  }

  @override
  String toString() {
    return 'Test.$name(${printArguments()})';
  }
}

class Operand extends Expression {
  Operand(this.operator, this.value);

  String operator;

  Expression value;

  @override
  Object? resolve(Context context) {
    return value.resolve(context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    value.apply(visitor);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $value)';
  }
}

class Compare extends Expression {
  Compare(this.value, this.operands);

  Expression value;

  List<Operand> operands;

  @override
  Object? resolve(Context context) {
    var left = value.resolve(context);
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
  void visitChildrens(NodeVisitor visitor) {
    value.apply(visitor);
    operands.forEach(visitor);
  }

  @override
  String toString() {
    return 'Compare($value, $operands)';
  }
}

class Condition extends Expression {
  Condition(this.test, this.value, [this.orElse]);

  Expression test;

  Expression value;

  Expression? orElse;

  @override
  Object? resolve(Context context) {
    if (boolean(test.resolve(context))) {
      return value.resolve(context);
    }

    return orElse?.resolve(context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    test.apply(visitor);
    value.apply(visitor);
    orElse?.apply(visitor);
  }

  @override
  String toString() {
    return orElse == null
        ? 'Condition($test, $value)'
        : 'Condition($test, $value, $orElse)';
  }
}

abstract class Literal extends Expression {}

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
    return 'Constant(${repr(value, true)})';
  }
}

class TupleLiteral extends Literal implements Assignable {
  TupleLiteral(this.values, [AssignContext? context]) {
    context = context ?? AssignContext.load;
  }

  List<Expression> values;

  @override
  AssignContext get context {
    if (values.isEmpty) {
      return AssignContext.load;
    }

    final first = values.first;
    return first is Assignable ? first.context : AssignContext.load;
  }

  @override
  set context(AssignContext context) {
    if (values.isEmpty) {
      return;
    }

    for (final value in values) {
      if (value is! Assignable) {
        throw TypeError();
      }

      value.context = context;
    }
  }

  @override
  bool get canAssign {
    return values.every((value) => value is Assignable && !value.canAssign);
  }

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        values.length, (index) => values[index].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        values.length, (index) => values[index].resolve(context));
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    values.forEach(visitor);
  }

  @override
  String toString() {
    return 'Tuple(${values.join(', ')})';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.values);

  List<Expression> values;

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        values.length, (index) => values[index].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        values.length, (index) => values[index].resolve(context));
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    values.forEach(visitor);
  }

  @override
  String toString() {
    return 'List(${values.join(', ')})';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.dict);

  Map<Expression, Expression> dict;

  @override
  Map<Object?, Object?> asConst(Context context) {
    return dict.map<Object?, Object?>((key, value) =>
        MapEntry<Object?, Object?>(
            key.asConst(context), value.asConst(context)));
  }

  @override
  Map<Object?, Object?> resolve(Context context) {
    return dict.map<Object?, Object?>((key, value) =>
        MapEntry<Object?, Object?>(
            key.resolve(context), value.resolve(context)));
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    dict.forEach((key, value) {
      key.apply(visitor);
      value.apply(visitor);
    });
  }

  @override
  String toString() {
    return 'Dict $dict';
  }
}

class Unary extends Expression {
  Unary(this.operator, this.value);

  String operator;

  Expression value;

  @override
  Object? resolve(Context context) {
    final value = this.value.resolve(context);

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
  void visitChildrens(NodeVisitor visitor) {
    value.apply(visitor);
  }

  @override
  String toString() {
    return 'Unary(\'$operator\', $value)';
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
  void visitChildrens(NodeVisitor visitor) {
    left.apply(visitor);
    right.apply(visitor);
  }

  @override
  String toString() {
    return 'Binary(\'$operator\', $left, $right)';
  }
}
