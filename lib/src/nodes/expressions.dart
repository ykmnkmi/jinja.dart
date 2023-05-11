part of '../nodes.dart';

class Impossible implements Exception {}

@internal
const Object defaultObject = Object();

@internal
const Constant defaultExpression = Constant(value: defaultObject);

abstract class Expression extends Node {
  const Expression();

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

abstract class Assignable implements Expression {
  bool get canAssign;

  AssignContext get context;

  @override
  Assignable copyWith({AssignContext? context});
}

class Name extends Expression implements Assignable {
  const Name({required this.name, this.context = AssignContext.load});

  final String name;

  @override
  final AssignContext context;

  @override
  bool get canAssign {
    return context == AssignContext.store;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitName(this, context);
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
  Name copyWith({String? name, AssignContext? context}) {
    return Name(name: name ?? this.name, context: context ?? this.context);
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
  const NamespaceRef({required this.name, required this.attribute});

  final String name;

  final String attribute;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNamespaceRef(this, context);
  }

  @override
  NamespaceValue resolve(Context context) {
    return NamespaceValue(name, attribute);
  }

  @override
  NamespaceRef copyWith({String? name, String? attribute}) {
    return NamespaceRef(
      name: name ?? this.name,
      attribute: attribute ?? this.attribute,
    );
  }

  @override
  String toString() {
    return 'NamespaceRef($name, $attribute)';
  }
}

abstract class Literal extends Expression {
  const Literal();
}

class Constant extends Literal {
  const Constant({required this.value});

  final Object? value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConstant(this, context);
  }

  @override
  Object? asConst(Context context) {
    return value;
  }

  @override
  Object? resolve(Context context) {
    return value;
  }

  @override
  Constant copyWith({Object? value = defaultObject}) {
    return Constant(value: value == defaultObject ? this.value : value);
  }

  @override
  String toString() {
    return 'Constant($value)';
  }
}

class Tuple extends Literal implements Assignable {
  const Tuple({required this.values, this.context = AssignContext.load});

  final List<Expression> values;

  @override
  final AssignContext context;

  @override
  bool get canAssign {
    bool test(Expression value) {
      return value is Assignable && value.canAssign;
    }

    return values.every(test);
  }

  @override
  List<Node> get children {
    return values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTuple(this, context);
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
  Tuple copyWith({List<Expression>? values, AssignContext? context}) {
    return Tuple(
      values: values ?? this.values,
      context: context ?? this.context,
    );
  }

  @override
  String toString() {
    return 'Tuple(${values.join(', ')})';
  }
}

class Array extends Literal {
  const Array({required this.values});

  final List<Expression> values;

  @override
  List<Node> get children {
    return values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitArray(this, context);
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
  Array copyWith({List<Expression>? values}) {
    return Array(values: values ?? this.values);
  }

  @override
  String toString() {
    return 'Array(${values.join(', ')})';
  }
}

class Pair extends Expression {
  const Pair({required this.key, required this.value});

  final Expression key;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[key, value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPair(this, context);
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
  Pair copyWith({Expression? key, Expression? value}) {
    return Pair(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}

class Dict extends Literal {
  const Dict({required this.pairs});

  final List<Pair> pairs;

  @override
  List<Node> get children {
    return pairs;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDict(this, context);
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
  Dict copyWith({List<Pair>? pairs}) {
    return Dict(pairs: pairs ?? this.pairs);
  }

  @override
  String toString() {
    return 'Dict(${pairs.join(', ')})';
  }
}

class Condition extends Expression {
  const Condition({
    required this.test,
    required this.value,
    this.orElse,
  });

  final Expression test;

  final Expression value;

  final Expression? orElse;

  @override
  List<Node> get children {
    return <Node>[test, value, if (orElse != null) orElse!];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCondition(this, context);
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
  Condition copyWith({
    Expression? test,
    Expression? value,
    Expression? orElse = defaultExpression,
  }) {
    return Condition(
      test: test ?? this.test,
      value: value ?? this.value,
      orElse: orElse == defaultExpression ? this.orElse : orElse,
    );
  }

  @override
  String toString() {
    return 'Condition($test, $value, $orElse)';
  }
}

class Keyword extends Expression {
  const Keyword({required this.key, required this.value});

  final String key;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitKeyword(this, context);
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
  Keyword copyWith({String? key, Expression? value}) {
    return Keyword(key: key ?? this.key, value: value ?? this.value);
  }

  Pair toPair() {
    return Pair(key: Constant(value: key), value: value);
  }

  @override
  String toString() {
    return 'Keyword($key, $value)';
  }
}

typedef Callback<T> = T Function(List<Object?>, Map<Symbol, Object?>);

abstract class Callable extends Expression {
  const Callable({
    this.arguments = const <Expression>[],
    this.keywords = const <Keyword>[],
    this.dArguments,
    this.dKeywords,
  });

  final List<Expression> arguments;

  final List<Keyword> keywords;

  final Expression? dArguments;

  final Expression? dKeywords;

  @override
  List<Node> get children {
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
      var arguments = dArguments.asConst(context);

      if (arguments is! Iterable) {
        throw TypeError();
      }

      positional.addAll(arguments);
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

  @override
  Callable copyWith({
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  });
}

class Call extends Callable {
  const Call({
    required this.expression,
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  });

  final Expression expression;

  @override
  List<Node> get children {
    return <Node>[expression, ...super.children];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
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
  Call copyWith({
    Expression? expression,
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  }) {
    return Call(
      expression: expression ?? this.expression,
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
      dArguments: dArguments ?? this.dArguments,
      dKeywords: dKeywords ?? this.dKeywords,
    );
  }

  @override
  String toString() {
    return 'Call($expression)';
  }
}

class Filter extends Callable {
  const Filter({
    required this.name,
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  });

  final String name;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilter(this, context);
  }

  @override
  Object? asConst(Context context) {
    throw Impossible();
  }

  @override
  Object? resolve(Context context) {
    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context.filter(name, positional, named);
    }

    return apply(context, callback);
  }

  @override
  Filter copyWith({
    String? name,
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  }) {
    return Filter(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
      dArguments: dArguments ?? this.dArguments,
      dKeywords: dKeywords ?? this.dKeywords,
    );
  }

  @override
  String toString() {
    return 'Filter($name)';
  }
}

class Test extends Callable {
  const Test({
    required this.name,
    super.arguments,
    super.keywords,
    super.dArguments,
    super.dKeywords,
  });

  final String name;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTest(this, context);
  }

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
  Test copyWith({
    String? name,
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  }) {
    return Test(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
      dArguments: dArguments ?? this.dArguments,
      dKeywords: dKeywords ?? this.dKeywords,
    );
  }

  @override
  String toString() {
    return 'Test($name)';
  }
}

class Item extends Expression {
  const Item({required this.key, required this.value});

  final Expression key;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[key, value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitItem(this, context);
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
  Item copyWith({Expression? key, Expression? value}) {
    return Item(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  String toString() {
    return 'Item($key, $value)';
  }
}

class Attribute extends Expression {
  const Attribute({required this.attribute, required this.value});

  final String attribute;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAttribute(this, context);
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
  Attribute copyWith({String? attribute, Expression? value}) {
    return Attribute(
      attribute: attribute ?? this.attribute,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return 'Attribute($attribute, $value)';
  }
}

class Concat extends Expression {
  const Concat({required this.values});

  final List<Expression> values;

  @override
  List<Node> get children {
    return values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConcat(this, context);
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

    return buffer.toString();
  }

  @override
  Concat copyWith({List<Expression>? values}) {
    return Concat(values: values ?? this.values);
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
  const Operand({required this.operator, required this.value});

  final CompareOperator operator;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOperand(this, context);
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
  Operand copyWith({CompareOperator? operator, Expression? value}) {
    return Operand(
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
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
  const Compare({required this.value, required this.operands});

  final Expression value;

  final List<Operand> operands;

  @override
  List<Node> get children {
    return <Node>[value, ...operands];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
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
  Compare copyWith({Expression? value, List<Operand>? operands}) {
    return Compare(
      value: value ?? this.value,
      operands: operands ?? this.operands,
    );
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
  const Unary({required this.operator, required this.value});

  final UnaryOperator operator;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitUnary(this, context);
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
  Unary copyWith({UnaryOperator? operator, Expression? value}) {
    return Unary(
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
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
  const Binary({
    required this.operator,
    required this.left,
    required this.right,
  });

  final T operator;

  final Expression left;

  final Expression right;

  @override
  List<Node> get children {
    return <Node>[left, right];
  }

  @override
  Binary<T> copyWith({T? operator, Expression? left, Expression? right});
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
  const Scalar({
    required super.operator,
    required super.left,
    required super.right,
  });

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitScalar(this, context);
  }

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
  Scalar copyWith({
    ScalarOperator? operator,
    Expression? left,
    Expression? right,
  }) {
    return Scalar(
      operator: operator ?? this.operator,
      left: left ?? this.left,
      right: right ?? this.right,
    );
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
  const Logical({
    required super.operator,
    required super.left,
    required super.right,
  });

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitLogical(this, context);
  }

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
  Logical copyWith({
    LogicalOperator? operator,
    Expression? left,
    Expression? right,
  }) {
    return Logical(
      operator: operator ?? this.operator,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  @override
  String toString() {
    return 'Logical(${operator.name}, $left, $right)';
  }
}
