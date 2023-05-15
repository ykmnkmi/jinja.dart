part of '../nodes.dart';

const Object _object = Object();

const Constant _expression = Constant(value: _object);

abstract class Expression extends Node {
  const Expression();
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
  Constant copyWith({Object? value = _object}) {
    return Constant(value: value == _object ? this.value : value);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTuple(this, context);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitArray(this, context);
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

typedef Pair = ({
  Expression key,
  Expression value,
});

class Dict extends Literal {
  const Dict({required this.pairs});

  final List<Pair> pairs;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDict(this, context);
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
    required this.trueValue,
    this.falseValue,
  });

  final Expression test;

  final Expression trueValue;

  final Expression? falseValue;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCondition(this, context);
  }

  @override
  Condition copyWith({
    Expression? test,
    Expression? trueValue,
    Expression? orElse = _expression,
  }) {
    return Condition(
      test: test ?? this.test,
      trueValue: trueValue ?? this.trueValue,
      falseValue: orElse == _expression ? this.falseValue : orElse,
    );
  }

  @override
  String toString() {
    return 'Condition($test, $trueValue, $falseValue)';
  }
}

typedef Keyword = ({String key, Expression value});

typedef Parameters = (List<Object?>, Map<Symbol, Object?>);

class Calling extends Expression {
  const Calling({
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCalling(this, context);
  }

  @override
  Calling copyWith({
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments = _expression,
    Expression? dKeywords = _expression,
  }) {
    return Calling(
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
      dArguments: dArguments == _expression ? this.dArguments : dArguments,
      dKeywords: dKeywords == _expression ? this.dKeywords : dKeywords,
    );
  }
}

class Call extends Expression {
  const Call({
    required this.expression,
    this.calling = const Calling(),
  });

  final Expression expression;

  final Calling calling;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
  }

  @override
  Call copyWith({Expression? value, Calling? calling}) {
    return Call(
      expression: value ?? this.expression,
      calling: calling ?? this.calling,
    );
  }

  @override
  String toString() {
    return 'Call($expression)';
  }
}

class Filter extends Expression {
  const Filter({
    required this.name,
    this.calling = const Calling(),
  });

  final String name;

  final Calling calling;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilter(this, context);
  }

  @override
  Filter copyWith({String? name, Calling? calling}) {
    return Filter(name: name ?? this.name, calling: calling ?? this.calling);
  }

  @override
  String toString() {
    return 'Filter($name)';
  }
}

class Test extends Expression {
  const Test({
    required this.name,
    this.calling = const Calling(),
  });

  final String name;

  final Calling calling;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTest(this, context);
  }

  @override
  Test copyWith({String? name, Calling? calling}) {
    return Test(name: name ?? this.name, calling: calling ?? this.calling);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitItem(this, context);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAttribute(this, context);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConcat(this, context);
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
  notContains;

  static CompareOperator parse(String operator) {
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
        // TODO(expressions): update error message
        throw UnsupportedError(operator);
    }
  }
}

typedef Operand = ({CompareOperator operator, Expression value});

class Compare extends Binary<CompareOperator> {
  const Compare({
    required super.operator,
    required super.left,
    required super.right,
  });

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
  }

  @override
  Compare copyWith({
    CompareOperator? operator,
    Expression? left,
    Expression? right,
  }) {
    return Compare(
      operator: operator ?? this.operator,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  @override
  String toString() {
    return 'Compare(${operator.name}, $left, $right)';
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitUnary(this, context);
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
