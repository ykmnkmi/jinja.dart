part of '../nodes.dart';

enum AssignContext {
  load,
  store,
  parameter,
}

class Impossible implements Exception {}

abstract class Expression extends Node {
  const Expression();

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExpression(this, context);
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
    bool test(Expression value) {
      return value is Assignable && !value.canAssign;
    }

    return values.every(test);
  }

  @override
  List<Node> get childrens {
    return values;
  }

  @override
  List<Object?> asConst(Context context) {
    Object? generator(int index) {
      return values[index].asConst(context);
    }

    return List<Object?>.generate(values.length, generator);
  }

  @override
  List<Object?> resolve(Context context) {
    Object? generator(int index) {
      return values[index].resolve(context);
    }

    return List<Object?>.generate(values.length, generator);
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var index = 0; index < values.length; index += 1) {
      values[index].update(updater);
      values[index] = updater(values[index]);
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
    Object? generator(int index) {
      return values[index].asConst(context);
    }

    return List<Object?>.generate(values.length, generator);
  }

  @override
  List<Object?> resolve(Context context) {
    Object? generator(int index) {
      return values[index].resolve(context);
    }

    return List<Object?>.generate(values.length, generator);
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var index = 0; index < values.length; index += 1) {
      values[index].update(updater);
      values[index] = updater(values[index]);
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
      key.asConst(context),
      value.asConst(context),
    );
  }

  @override
  MapEntry<Object?, Object?> resolve(Context context) {
    return MapEntry<Object?, Object?>(
      key.resolve(context),
      value.resolve(context),
    );
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
    return pairs;
  }

  @override
  Map<Object?, Object?> asConst(Context context) {
    MapEntry<Object?, Object?> toElement(Pair pair) {
      return pair.asConst(context);
    }

    var entries = pairs.map<MapEntry<Object?, Object?>>(toElement);
    return Map<Object?, Object?>.fromEntries(entries);
  }

  @override
  Map<Object?, Object?> resolve(Context context) {
    MapEntry<Object?, Object?> toElement(Pair pair) {
      return pair.resolve(context);
    }

    var entries = pairs.map<MapEntry<Object?, Object?>>(toElement);
    return Map<Object?, Object?>.fromEntries(entries);
  }

  @override
  void update(ExpressionUpdater updater) {
    for (var index = 0; index < pairs.length; index += 1) {
      pairs[index].update(updater);
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
    var orElse = this.orElse;
    return <Node>[test, value, if (orElse != null) orElse];
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
  Callable({
    List<Expression>? arguments,
    List<Keyword>? keywords,
    this.dArguments,
    this.dKeywords,
  })  : arguments = arguments ?? <Expression>[],
        keywords = keywords ?? <Keyword>[];

  List<Expression> arguments;

  List<Keyword> keywords;

  Expression? dArguments;

  Expression? dKeywords;

  @override
  List<Node> get childrens {
    return <Node>[
      ...arguments,
      ...keywords,
      if (dArguments != null) dArguments!,
      if (dKeywords != null) dKeywords!
    ];
  }

  Object? applyAsConst(Context context, Callback<Object?> callback) {
    List<Object?> positional;

    if (arguments.isEmpty) {
      positional = <Object?>[];
    } else {
      Object? generator(int index) {
        return arguments[index].asConst(context);
      }

      positional = List<Object?>.generate(arguments.length, generator);
    }

    var named = <Symbol, Object?>{};

    for (var argument in keywords) {
      named[Symbol(argument.key)] = argument.asConst(context);
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

      void action(String key, Object? value) {
        named[Symbol(key)] = value;
      }

      resolvedKeywords.cast<String, Object?>().forEach(action);
    }

    return callback(positional, named);
  }

  T apply<T extends Object?>(Context context, Callback<T> callback) {
    List<Object?> positional;

    if (arguments.isEmpty) {
      positional = <Object?>[];
    } else {
      Object? generator(int index) {
        return arguments[index].resolve(context);
      }

      positional = List<Object?>.generate(arguments.length, generator);
    }

    var named = <Symbol, Object?>{};

    for (var keyword in keywords) {
      named[Symbol(keyword.key)] = keyword.resolve(context);
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

      void action(String key, Object? value) {
        named[Symbol(key)] = value;
      }

      resolvedKeywords.cast<String, Object?>().forEach(action);
    }

    return callback(positional, named);
  }

  String format({bool comma = false}) {
    var result = '';

    if (arguments.isNotEmpty) {
      if (comma) {
        result = '$result, ';
      } else {
        comma = true;
      }

      result = '$result${arguments.join(', ')}';
    }

    if (keywords.isNotEmpty) {
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
    for (var i = 0; i < arguments.length; i += 1) {
      arguments[i] = updater(arguments[i]);
      arguments[i].update(updater);
    }

    for (var i = 0; i < keywords.length; i += 1) {
      keywords[i].update(updater);
    }

    var dArguments = this.dArguments;

    if (dArguments != null) {
      dArguments = updater(dArguments);
      dArguments.update(updater);
      this.dArguments = dArguments;
    }

    var dKeywords = this.dKeywords;

    if (dKeywords != null) {
      dKeywords = updater(dKeywords);
      dKeywords.update(updater);
      this.dKeywords = dKeywords;
    }
  }
}

class Call extends Callable {
  Call(
    this.expression, {
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  });

  Expression expression;

  @override
  List<Node> get childrens {
    return <Node>[expression, ...super.childrens];
  }

  @override
  Object? asConst(Context context) {
    var function = expression.asConst(context);

    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context(function, positional, named);
    }

    return applyAsConst(context, callback);
  }

  @override
  Object? resolve(Context context) {
    var function = expression.resolve(context);

    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context(function, positional, named);
    }

    return apply<Object?>(context, callback);
  }

  @override
  void update(ExpressionUpdater updater) {
    expression = updater(expression);
    expression.update(updater);
    super.update(updater);
  }

  @override
  String toString() {
    return 'Call($expression${this.format(comma: true)})';
  }
}

class Filter extends Callable {
  Filter(
    this.name, {
    Expression? expression,
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  })
  // remove after better null safety promotion
  // ignore: prefer_initializing_formals
  : hasExpression = expression != null;

  String name;

  bool hasExpression;

  set expression(Expression? expression) {
    if (hasExpression) {
      if (expression == null) {
        hasExpression = false;
        arguments = arguments.sublist(1);
        return;
      }

      arguments[0] = expression;
    } else if (expression != null) {
      hasExpression = true;
      arguments = <Expression>[expression, ...arguments];
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
  Test(
    this.name, {
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  });

  String name;

  @override
  Object? asConst(Context context) {
    if (context.environment.tests.containsKey(name)) {
      Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
        return context.test(name, positional, named);
      }

      return applyAsConst(context, callback);
    }

    throw Impossible();
  }

  @override
  bool resolve(Context context) {
    bool callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context.test(name, positional, named);
    }

    return apply<bool>(context, callback);
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
    key = updater(key);
    key.update(updater);
    value = updater(value);
    value.update(updater);
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
    value = updater(value);
    value.update(updater);
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
    value = updater(value);
    value.update(updater);
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

  // TODO: try reduce operands if imposible
  @override
  Object? asConst(Context context) {
    Object? toElement(Expression expression) {
      return expression.asConst(context);
    }

    return values.map<Object?>(toElement).join();
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
      values[i] = updater(values[i]);
      values[i].update(updater);
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
    value = updater(value);
    value.update(updater);
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

  // TODO: try reduce operands if imposible
  @override
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
    value = updater(value);
    value.update(updater);

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
    value = updater(value);
    value.update(updater);
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
        // TODO: dynamic invocation
        // ignore: avoid_dynamic_calls
        return -value;
      case UnaryOperator.not:
        return !boolean(value);
    }
  }
}

abstract class Binary<T extends Enum> extends Expression {
  Binary(this.operator, this.left, this.right);

  T operator;

  Expression left;

  Expression right;

  @override
  List<Node> get childrens {
    return <Node>[left, right];
  }

  @override
  void update(ExpressionUpdater updater) {
    left = updater(left);
    left.update(updater);
    right = updater(right);
    right.update(updater);
  }
}

enum ScalarOperator {
  power,
  module,
  floorDivision,
  division,
  multiple,
  minus,
  plus,
}

class Scalar extends Binary<ScalarOperator> {
  Scalar(super.operator, super.left, super.right);

  @override
  Object? asConst(Context context) {
    try {
      var left = this.left.asConst(context);
      var right = this.right.asConst(context);
      return calc(operator, left, right);
    } catch (error) {
      throw Impossible();
    }
  }

  @override
  Object? resolve(Context context) {
    var left = this.left.resolve(context);
    var right = this.right.resolve(context);
    return calc(operator, left, right);
  }

  @override
  String toString() {
    return 'Binary(${operator.name}, $left, $right)';
  }

  // TODO: dynamic invocation
  static Object? calc(ScalarOperator operator, dynamic left, dynamic right) {
    switch (operator) {
      case ScalarOperator.power:
        return math.pow(left as num, right as num);
      case ScalarOperator.module:
        // ignore: avoid_dynamic_calls
        return left % right;
      case ScalarOperator.floorDivision:
        // ignore: avoid_dynamic_calls
        return left ~/ right;
      case ScalarOperator.division:
        // ignore: avoid_dynamic_calls
        return left / right;
      case ScalarOperator.multiple:
        // ignore: avoid_dynamic_calls
        return left * right;
      case ScalarOperator.minus:
        // ignore: avoid_dynamic_calls
        return left - right;
      case ScalarOperator.plus:
        // ignore: avoid_dynamic_calls
        return left + right;
    }
  }
}

enum LogicalOperator {
  or,
  and,
}

class Logical extends Binary<LogicalOperator> {
  Logical(super.operator, super.left, super.right);

  @override
  Object? asConst(Context context) {
    try {
      var left = this.left.asConst(context);

      switch (operator) {
        case LogicalOperator.or:
          return boolean(left) ? left : right.asConst(context);
        case LogicalOperator.and:
          return boolean(left) ? right.asConst(context) : left;
      }
    } catch (error) {
      throw Impossible();
    }
  }

  @override
  Object? resolve(Context context) {
    var left = this.left.resolve(context);

    switch (operator) {
      case LogicalOperator.or:
        return boolean(left) ? left : right.resolve(context);

      case LogicalOperator.and:
        return boolean(left) ? right.resolve(context) : left;
    }
  }

  @override
  String toString() {
    return 'Logical(${operator.name}, $left, $right)';
  }
}
