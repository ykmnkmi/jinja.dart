part of '../nodes.dart';

enum AssignContext {
  load,
  store,
  parameter,
}

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

  void update(ExpressionUpdater updater) {}
}

mixin Assignable on Expression {
  bool get canAssign;

  abstract AssignContext context;
}

class Name extends Expression implements Assignable {
  Name(this.name, {this.context = AssignContext.load});

  String name;

  @override
  AssignContext context;

  @override
  bool get canAssign {
    return context == AssignContext.store;
  }

  @override
  Object? asConst(Context context) {
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
    if (context == AssignContext.load) {
      return 'Name($name)';
    }

    return 'Name($name, $context)';
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

class Tuple extends Literal implements Assignable {
  Tuple(this.values, [AssignContext? context]) {
    context = context ?? AssignContext.load;
  }

  List<Expression> values;

  @override
  AssignContext get context {
    if (values.isEmpty) {
      return AssignContext.load;
    }

    var first = values.first;

    if (first is Assignable) {
      return first.context;
    }

    return AssignContext.load;
  }

  @override
  set context(AssignContext context) {
    if (values.isEmpty) {
      return;
    }

    for (var value in values) {
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
  List<Node> get childrens {
    return values;
  }

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        values.length, (i) => values[i].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        values.length, (i) => values[i].resolve(context));
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var i = 0; i < values.length; i += 1) {
      values[i].update(updater);
      values[i] = updater(values[i]);
    }
  }

  @override
  String toString() {
    return 'Tuple(${values.join(', ')})';
  }
}

class Array extends Literal {
  Array(this.values);

  List<Expression> values;

  @override
  List<Node> get childrens {
    return values;
  }

  @override
  List<Object?> asConst(Context context) {
    return List<Object?>.generate(
        values.length, (i) => values[i].asConst(context));
  }

  @override
  List<Object?> resolve(Context context) {
    return List<Object?>.generate(
        values.length, (i) => values[i].resolve(context));
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var i = 0; i < values.length; i += 1) {
      values[i].update(updater);
      values[i] = updater(values[i]);
    }
  }

  @override
  String toString() {
    return 'Array(${values.join(', ')})';
  }
}

class Pair extends Expression {
  Pair(this.key, this.value);

  Expression key;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[key, value];
  }

  @override
  MapEntry<Object?, Object?> asConst(Context context) {
    return MapEntry<Object?, Object?>(
        key.asConst(context), value.asConst(context));
  }

  @override
  MapEntry<Object?, Object?> resolve(Context context) {
    return MapEntry<Object?, Object?>(
        key.resolve(context), value.resolve(context));
  }

  @override
  void update(ExpressionUpdater updater) {
    key = updater(key);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}

class Dict extends Literal {
  Dict(this.pairs);

  List<Pair> pairs;

  @override
  List<Node> get childrens {
    return <Node>[for (var pair in pairs) ...pair.childrens];
  }

  @override
  Map<Object?, Object?> asConst(Context context) {
    return Map<Object?, Object?>.fromEntries(
        pairs.map<MapEntry<Object?, Object?>>((pair) => pair.asConst(context)));
  }

  @override
  Map<Object?, Object?> resolve(Context context) {
    return Map<Object?, Object?>.fromEntries(
        pairs.map<MapEntry<Object?, Object?>>((pair) => pair.resolve(context)));
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var i = 0; i < pairs.length; i += 1) {
      pairs[i].update(updater);
    }
  }

  @override
  String toString() {
    return 'Dict(${pairs.join(', ')})';
  }
}

class Condition extends Expression {
  Condition(this.test, this.value, [this.orElse]);

  Expression test;

  Expression value;

  Expression? orElse;

  @override
  List<Node> get childrens {
    return <Node>[test, value, if (orElse != null) orElse!];
  }

  @override
  Object? asConst(Context context) {
    if (boolean(test.asConst(context))) {
      return value.asConst(context);
    }

    return orElse?.asConst(context);
  }

  @override
  Object? resolve(Context context) {
    if (boolean(test.resolve(context))) {
      return value.resolve(context);
    }

    return orElse?.resolve(context);
  }

  @override
  void update(ExpressionUpdater updater) {
    test.update(updater);
    test = updater(test);
    value.update(updater);
    value = updater(value);

    var orElse = this.orElse;

    if (orElse != null) {
      orElse.update(updater);
      this.orElse = updater(orElse);
    }
  }

  @override
  String toString() {
    if (orElse == null) {
      return 'Condition($test, $value)';
    }

    return 'Condition($test, $value, $orElse)';
  }
}

class Keyword extends Expression {
  Keyword(this.key, this.value);

  String key;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[value];
  }

  @override
  Object? asConst(Context context) {
    return value.asConst(context);
  }

  @override
  Object? resolve(Context context) {
    return value.resolve(context);
  }

  Pair toPair() {
    return Pair(Constant(key), value);
  }

  @override
  void update(ExpressionUpdater updater) {
    value = updater(value);
  }

  @override
  String toString() {
    return 'Keyword($key, $value)';
  }
}

typedef Callback<T> = T Function(List<Object?>, Map<Symbol, Object?>);

class Callable extends Expression {
  Callable({this.arguments, this.keywords, this.dArguments, this.dKeywords});

  List<Expression>? arguments;

  List<Keyword>? keywords;

  Expression? dArguments;

  Expression? dKeywords;

  @override
  List<Node> get childrens {
    return <Node>[
      ...?arguments,
      ...?keywords,
      if (dArguments != null) dArguments!,
      if (dKeywords != null) dKeywords!
    ];
  }

  Object? applyConst(Context context, Callback<Object?> callback) {
    var arguments = this.arguments;
    List<Object?> positional;

    if (arguments == null) {
      positional = <Object?>[];
    } else {
      positional = List<Object?>.generate(
          arguments.length, (i) => arguments[i].asConst(context));
    }

    var named = <Symbol, Object?>{};
    var keywords = this.keywords;

    if (keywords != null) {
      for (var argument in keywords) {
        named[Symbol(argument.key)] = argument.asConst(context);
      }
    }

    var dArguments = this.dArguments;

    if (dArguments != null) {
      positional.addAll(dArguments.asConst(context) as Iterable<Object?>);
    }

    var dKeywords = this.dKeywords;

    if (dKeywords != null) {
      var resolvedKeywords = dKeywords.asConst(context);

      if (resolvedKeywords is! Map) {
        throw TypeError();
      }

      resolvedKeywords.cast<String, Object?>().forEach((key, value) {
        named[Symbol(key)] = value;
      });
    }

    return callback(positional, named);
  }

  T apply<T extends Object?>(Context context, Callback<T> callback) {
    var arguments = this.arguments;
    List<Object?> positional;

    if (arguments == null) {
      positional = <Object?>[];
    } else {
      positional = List<Object?>.generate(
          arguments.length, (i) => arguments[i].resolve(context));
    }

    var named = <Symbol, Object?>{};
    var keywords = this.keywords;

    if (keywords != null) {
      for (var argument in keywords) {
        named[Symbol(argument.key)] = argument.resolve(context);
      }
    }

    var dArguments = this.dArguments;

    if (dArguments != null) {
      positional.addAll(dArguments.resolve(context) as Iterable<Object?>);
    }

    var dKeywords = this.dKeywords;

    if (dKeywords != null) {
      var resolvedKeywords = dKeywords.resolve(context);

      if (resolvedKeywords is! Map) {
        throw TypeError();
      }

      resolvedKeywords.cast<String, Object?>().forEach((key, value) {
        named[Symbol(key)] = value;
      });
    }

    return callback(positional, named);
  }

  String format({bool comma = false}) {
    var result = '';
    var arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result = '$result${arguments.join(', ')}';
    }

    var keywords = this.keywords;

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

  @override
  void update(ExpressionUpdater updater) {
    var arguments = this.arguments;

    if (arguments != null) {
      for (var i = 0; i < arguments.length; i += 1) {
        arguments[i].update(updater);
        arguments[i] = updater(arguments[i]);
      }
    }

    var keywords = this.keywords;

    if (keywords != null) {
      for (var i = 0; i < keywords.length; i += 1) {
        keywords[i].update(updater);
      }
    }

    var dArguments = this.dArguments;

    if (dArguments != null) {
      dArguments.update(updater);
      this.dArguments = updater(dArguments);
    }

    var dKeywords = this.dKeywords;

    if (dKeywords != null) {
      dKeywords.update(updater);
      this.dKeywords = updater(dKeywords);
    }
  }
}

class Call extends Callable {
  Call(this.expression,
      {super.arguments, super.keywords, super.dArguments, super.dKeywords});

  Expression expression;

  @override
  List<Node> get childrens {
    return <Node>[expression, ...super.childrens];
  }

  @override
  Object? asConst(Context context) {
    var function = expression.asConst(context);
    return applyConst(context, (positional, named) {
      return context(function, positional, named);
    });
  }

  @override
  Object? resolve(Context context) {
    var function = expression.resolve(context);
    return apply(context, (positional, named) {
      return context(function, positional, named);
    });
  }

  @override
  void update(ExpressionUpdater updater) {
    expression.update(updater);
    expression = updater(expression);
    super.update(updater);
  }

  @override
  String toString() {
    return 'Call($expression${this.format(comma: true)})';
  }
}

class Filter extends Callable {
  Filter(this.name,
      {Expression? expression,
      super.arguments,
      super.keywords,
      super.dArguments,
      super.dKeywords})
      // remove after better null safety promotion
      // ignore: prefer_initializing_formals
      : hasExpression = expression != null;

  String name;

  bool hasExpression;

  set expression(Expression? expression) {
    var arguments = this.arguments;

    if (arguments == null) {
      if (expression == null) {
        hasExpression = false;
        return;
      }

      hasExpression = true;
      this.arguments = <Expression>[expression];
      return;
    }

    if (hasExpression) {
      if (expression == null) {
        hasExpression = false;
        arguments.removeAt(0);
        return;
      }

      arguments[0] = expression;
      return;
    }

    if (expression != null) {
      hasExpression = true;
      arguments.insert(0, expression);
    }
  }

  @override
  Object? asConst(Context context) {
    throw Impossible();
  }

  @override
  Object? resolve(Context context) {
    return apply(context, (positional, named) {
      return context.filter(name, positional, named);
    });
  }

  @override
  String toString() {
    return 'Filter.$name(${this.format()})';
  }
}

class Test extends Callable {
  Test(this.name,
      {super.arguments, super.keywords, super.dArguments, super.dKeywords});

  String name;

  @override
  Object? asConst(Context context) {
    if (!context.environment.tests.containsKey(name)) {
      throw Impossible();
    }

    return applyConst(context, (positional, named) {
      return context.test(name, positional, named);
    });
  }

  @override
  bool resolve(Context context) {
    return apply<bool>(context, (positional, named) {
      return context.test(name, positional, named);
    });
  }

  @override
  String toString() {
    return 'Test.$name(${this.format()})';
  }
}

class Item extends Expression {
  factory Item.string(String key, Expression value) = ItemString;

  Item(this.key, this.value);

  Expression key;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[key, value];
  }

  @override
  Object? asConst(Context context) {
    var key = this.key.asConst(context);
    var value = this.value.asConst(context);
    return context.environment.getItem(value, key);
  }

  @override
  Object? resolve(Context context) {
    var key = this.key.resolve(context);
    var value = this.value.resolve(context);
    return context.environment.getItem(value, key);
  }

  @override
  void update(ExpressionUpdater updater) {
    key.update(updater);
    key = updater(key);
    value.update(updater);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Item($key, $value)';
  }
}

class ItemString extends Expression implements Item {
  ItemString(this.keyString, this.value);

  String keyString;

  @override
  Expression value;

  @override
  Expression get key {
    return Constant(keyString);
  }

  @override
  set key(Expression key) {
    if (key is Constant) {
      keyString = key.value as String;
    } else {
      throw ArgumentError.value(key);
    }
  }

  @override
  List<Node> get childrens {
    return <Node>[key, value];
  }

  @override
  Object? asConst(Context context) {
    var value = this.value.asConst(context);
    return context.environment.getItem(value, keyString);
  }

  @override
  Object? resolve(Context context) {
    var value = this.value.resolve(context);
    return context.environment.getItem(value, keyString);
  }

  @override
  void update(ExpressionUpdater updater) {
    value.update(updater);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Item.string($keyString, $value)';
  }
}

class Attribute extends Expression {
  Attribute(this.attribute, this.value);

  String attribute;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[value];
  }

  @override
  Object? asConst(Context context) {
    var value = this.value.asConst(context);
    return context.environment.getAttribute(value, attribute);
  }

  @override
  Object? resolve(Context context) {
    var value = this.value.resolve(context);
    return context.environment.getAttribute(value, attribute);
  }

  @override
  void update(ExpressionUpdater updater) {
    value.update(updater);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $value)';
  }
}

class Concat extends Expression {
  Concat(this.values);

  List<Expression> values;

  @override
  List<Node> get childrens {
    return values;
  }

  @override // TODO: try reduce operands if imposible
  Object? asConst(Context context) {
    return values.map<Object?>((value) => value.asConst(context)).join();
  }

  @override
  String resolve(Context context) {
    var buffer = StringBuffer();

    for (var expression in values) {
      buffer.write(expression.resolve(context));
    }

    return '$buffer';
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var i = 0; i < values.length; i += 1) {
      values[i].update(updater);
      values[i] = updater(values[i]);
    }
  }

  @override
  String toString() {
    return 'Concat(${values.join(', ')})';
  }
}

enum CompareOperator {
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  contains,
  notContains,
}

class Operand extends Expression {
  Operand(this.operator, this.value);

  CompareOperator operator;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[value];
  }

  @override
  Object? asConst(Context context) {
    return value.asConst(context);
  }

  @override
  Object? resolve(Context context) {
    return value.resolve(context);
  }

  @override
  void update(ExpressionUpdater updater) {
    value.update(updater);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Operand(${operator.name}, $value)';
  }

  static CompareOperator? operatorFrom(String operator) {
    switch (operator) {
      case 'eq':
        return CompareOperator.equal;
      case 'ne':
        return CompareOperator.notEqual;
      case 'lt':
        return CompareOperator.lessThan;
      case 'lteq':
        return CompareOperator.lessThanOrEqual;
      case 'gt':
        return CompareOperator.greaterThan;
      case 'gteq':
        return CompareOperator.greaterThanOrEqual;
      case 'in':
        return CompareOperator.contains;
      case 'notin':
        return CompareOperator.notContains;
      default:
        return null;
    }
  }
}

class Compare extends Expression {
  Compare(this.value, this.operands);

  Expression value;

  List<Operand> operands;

  @override
  List<Node> get childrens {
    return <Node>[value, ...operands];
  }

  @override // TODO: try reduce operands if imposible
  Object? asConst(Context context) {
    var temp = value.asConst(context);

    for (var operand in operands) {
      if (!calc(operand.operator, temp, temp = operand.asConst(context))) {
        return false;
      }
    }

    return true;
  }

  @override
  Object? resolve(Context context) {
    var temp = value.resolve(context);

    for (var operand in operands) {
      if (!calc(operand.operator, temp, temp = operand.resolve(context))) {
        return false;
      }
    }

    return true;
  }

  @override
  void update(ExpressionUpdater updater) {
    value.update(updater);
    value = updater(value);

    for (var i = 0; i < operands.length; i += 1) {
      operands[i].update(updater);
    }
  }

  @override
  String toString() {
    return 'Compare($value, $operands)';
  }

  static bool calc(CompareOperator operator, Object? left, Object? right) {
    switch (operator) {
      case CompareOperator.equal:
        return isEqual(left, right);
      case CompareOperator.notEqual:
        return isNotEqual(left, right);
      case CompareOperator.lessThan:
        return isLessThan(left, right);
      case CompareOperator.lessThanOrEqual:
        return isLessThanOrEqual(left, right);
      case CompareOperator.greaterThan:
        return isGreaterThan(left, right);
      case CompareOperator.greaterThanOrEqual:
        return isGreaterThanOrEqual(left, right);
      case CompareOperator.contains:
        return isIn(left, right);
      case CompareOperator.notContains:
        return !isIn(left, right);
    }
  }
}

enum UnaryOperator {
  plus,
  minus,
  not,
}

class Unary extends Expression {
  Unary(this.operator, this.value);

  UnaryOperator operator;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[value];
  }

  @override
  Object? asConst(Context context) {
    try {
      return calc(operator, value.asConst(context));
    } catch (error) {
      throw Impossible();
    }
  }

  @override
  Object? resolve(Context context) {
    return calc(operator, value.resolve(context));
  }

  @override
  void update(ExpressionUpdater updater) {
    value.update(updater);
    value = updater(value);
  }

  @override
  String toString() {
    return 'Unary(${operator.name}, $value)';
  }

  static Object? calc(UnaryOperator operator, dynamic value) {
    switch (operator) {
      case UnaryOperator.plus:
        // how i should implement this?
        return value;
      case UnaryOperator.minus:
        return -value;
      case UnaryOperator.not:
        return !boolean(value);
    }
  }
}

enum BinaryOperator {
  power,
  module,
  floorDivision,
  division,
  multiple,
  minus,
  plus,
  or,
  and,
}

class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  BinaryOperator operator;

  Expression left;

  Expression right;

  @override
  List<Node> get childrens {
    return <Node>[left, right];
  }

  @override
  Object? asConst(Context context) {
    try {
      return calc(operator, left.asConst(context), right.asConst(context));
    } catch (error) {
      throw Impossible();
    }
  }

  @override
  Object? resolve(Context context) {
    return calc(operator, left.resolve(context), right.resolve(context));
  }

  @override
  void update(ExpressionUpdater updater) {
    left.update(updater);
    left = updater(left);
    right.update(updater);
    right = updater(right);
  }

  @override
  String toString() {
    return 'Binary(${operator.name}, $left, $right)';
  }

  static Object? calc(BinaryOperator operator, dynamic left, dynamic right) {
    switch (operator) {
      case BinaryOperator.power:
        return math.pow(left as num, right as num);
      case BinaryOperator.module:
        return left % right;
      case BinaryOperator.floorDivision:
        return left ~/ right;
      case BinaryOperator.division:
        return left / right;
      case BinaryOperator.multiple:
        return left * right;
      case BinaryOperator.minus:
        return left - right;
      case BinaryOperator.plus:
        return left + right;
      case BinaryOperator.or:
        return boolean(left) ? left : right;
      case BinaryOperator.and:
        return boolean(left) ? right : left;
    }
  }
}
