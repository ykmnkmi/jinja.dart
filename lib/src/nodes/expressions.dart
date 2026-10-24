part of '/src/nodes.dart';

enum AssignContext { load, store, parameter }

final class Name extends Expression {
  const new({required this.name, this.context = AssignContext.load});

  const new store({required String name})
    : this(name: name, context: AssignContext.store);

  const new parameter({required String name})
    : this(name: name, context: AssignContext.parameter);

  final String name;

  final AssignContext context;

  @override
  bool get canAssign {
    return !const <String>{
      'null',
      'none',
      'None',
      'true',
      'True',
      'false',
      'False',
    }.contains(name);
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Name',
      'name': name,
      'context': context.name,
    };
  }
}

final class NsRef extends Expression {
  const new({required this.name, required this.attribute});

  final String name;

  final String attribute;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNsRef(this, context);
  }

  @override
  bool get canAssign {
    return true;
  }

  @override
  NsRef copyWith({String? name, String? attribute}) {
    return NsRef(
      name: name ?? this.name,
      attribute: attribute ?? this.attribute,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'NamespaceRef',
      'name': name,
      'attribute': attribute,
    };
  }
}

abstract base class Literal extends Expression {
  const new();
}

final class Constant extends Literal {
  const new({required this.value});

  final Object? value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConstant(this, context);
  }

  @override
  Constant copyWith({Object? value}) {
    return Constant(value: value ?? this.value);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Constant', 'value': value};
  }
}

final class Tuple extends Literal {
  const new({required this.values});

  final List<Expression> values;

  @override
  bool get canAssign {
    for (var value in values) {
      if (!value.canAssign) {
        return false;
      }
    }

    return true;
  }

  @override
  Iterable<Node> get childNodes sync* {
    yield* values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTuple(this, context);
  }

  @override
  Tuple copyWith({List<Expression>? values}) {
    return Tuple(values: values ?? this.values);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Tuple', 'values': values.toJson()};
  }
}

final class Array extends Literal {
  const new({required this.values});

  final List<Expression> values;

  @override
  Iterable<Node> get childNodes sync* {
    yield* values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitArray(this, context);
  }

  @override
  Array copyWith({List<Expression>? values}) {
    return Array(values: values ?? this.values);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Array', 'values': values.toJson()};
  }
}

final class Pair extends Helper {
  const new({required this.key, required this.value});

  final Expression key;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield key;
    yield value;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPair(this, context);
  }

  @override
  Pair copyWith({Expression? key, Expression? value}) {
    return Pair(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'key': key.toJson(), 'value': value.toJson()};
  }
}

final class Dict extends Literal {
  const new({required this.pairs});

  final List<Pair> pairs;

  @override
  Iterable<Node> get childNodes sync* {
    yield* pairs;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDict(this, context);
  }

  @override
  Dict copyWith({List<Pair>? pairs}) {
    return Dict(pairs: pairs ?? this.pairs);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Dict', 'pairs': pairs.toJson()};
  }
}

final class Condition extends Expression {
  const new({required this.test, required this.trueValue, this.falseValue});

  final Expression test;

  final Expression trueValue;

  final Expression? falseValue;

  @override
  Iterable<Node> get childNodes sync* {
    yield test;
    yield trueValue;

    if (falseValue case var falseValue?) {
      yield falseValue;
    }
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCondition(this, context);
  }

  @override
  Condition copyWith({
    Expression? test,
    Expression? trueValue,
    Expression? falseValue,
  }) {
    return Condition(
      test: test ?? this.test,
      trueValue: trueValue ?? this.trueValue,
      falseValue: falseValue ?? this.falseValue,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Condition',
      'test': test.toJson(),
      'trueValue': trueValue.toJson(),
      'falseValue': falseValue?.toJson(),
    };
  }
}

final class Keyword extends Helper {
  const new({required this.key, required this.value});

  final String key;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitKeyword(this, context);
  }

  @override
  Keyword copyWith({String? key, Expression? value}) {
    return Keyword(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'key': key, 'value': value.toJson()};
  }

  Pair toPair() {
    return Pair(
      key: Constant(value: key),
      value: value,
    );
  }
}

typedef Parameters = (List<Object?>, Map<Symbol, Object?>);

final class Calling extends Expression {
  const new({
    this.arguments = const <Expression>[],
    this.keywords = const <Keyword>[],
  });

  final List<Expression> arguments;

  final List<Keyword> keywords;

  @override
  Iterable<Node> get childNodes sync* {
    yield* arguments;
    yield* keywords;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCalling(this, context);
  }

  @override
  Calling copyWith({List<Expression>? arguments, List<Keyword>? keywords}) {
    return Calling(
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Calling',
      'arguments': arguments.toJson(),
      'keywords': keywords.toJson(),
    };
  }
}

final class Call extends Expression {
  const new({required this.value, this.calling = const Calling()});

  final Expression value;

  final Calling calling;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
    yield calling;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
  }

  @override
  Call copyWith({Expression? value, Calling? calling}) {
    return Call(value: value ?? this.value, calling: calling ?? this.calling);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Call',
      'value': value.toJson(),
      'calling': calling.toJson(),
    };
  }
}

final class Filter extends Expression {
  const new({
    required this.name,
    this.expression,
    this.calling = const Calling(),
  });

  final String name;

  final Expression? expression;

  final Calling calling;

  @override
  Iterable<Node> get childNodes sync* {
    if (expression case var expression?) {
      yield expression;
    }

    yield calling;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilter(this, context);
  }

  @override
  Filter copyWith({String? name, Expression? expression, Calling? calling}) {
    return Filter(
      name: name ?? this.name,
      expression: expression ?? this.expression,
      calling: calling ?? this.calling,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Filter',
      'name': name,
      'expression': expression?.toJson(),
      'calling': calling.toJson(),
    };
  }
}

final class Test extends Expression {
  const new({
    required this.name,
    required this.expression,
    this.calling = const Calling(),
  });

  final String name;

  final Expression expression;

  final Calling calling;

  @override
  Iterable<Node> get childNodes sync* {
    yield expression;
    yield calling;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTest(this, context);
  }

  @override
  Test copyWith({String? name, Expression? expression, Calling? calling}) {
    return Test(
      name: name ?? this.name,
      expression: expression ?? this.expression,
      calling: calling ?? this.calling,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Test',
      'name': name,
      'expression': expression.toJson(),
      'calling': calling.toJson(),
    };
  }
}

final class Item extends Expression {
  const new({required this.key, required this.value});

  final Expression key;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield key;
    yield value;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitItem(this, context);
  }

  @override
  Item copyWith({Expression? key, Expression? value}) {
    return Item(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Item',
      'key': key.toJson(),
      'value': value.toJson(),
    };
  }
}

final class Slice extends Expression {
  const new({this.start, this.stop, this.step});

  final Expression? start;

  final Expression? stop;

  final Expression? step;

  @override
  Iterable<Node> get childNodes sync* {
    if (start case var start?) {
      yield start;
    }

    if (stop case var stop?) {
      yield stop;
    }

    if (step case var step?) {
      yield step;
    }
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSlice(this, context);
  }

  @override
  Slice copyWith({Expression? start, Expression? stop, Expression? step}) {
    return Slice(
      start: start ?? this.start,
      stop: stop ?? this.stop,
      step: step ?? this.step,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Slice',
      'start': start?.toJson(),
      'stop': stop?.toJson(),
      'step': step?.toJson(),
    };
  }
}

final class Attribute extends Expression {
  const new({required this.attribute, required this.value});

  final String attribute;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
  }

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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Attribute',
      'attribute': attribute,
      'value': value.toJson(),
    };
  }
}

final class Concat extends Expression {
  const new({required this.values});

  final List<Expression> values;

  @override
  Iterable<Node> get childNodes sync* {
    yield* values;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConcat(this, context);
  }

  @override
  Concat copyWith({List<Expression>? values}) {
    return Concat(values: values ?? this.values);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Concat', 'values': values.toJson()};
  }
}

enum CompareOperator {
  equal('=='),
  notEqual('!='),
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  contains('in'),
  notContains('not in');

  new(this.symbol);

  final String symbol;

  static CompareOperator parse(String symbol) {
    return switch (symbol) {
      'eq' => CompareOperator.equal,
      'ne' => CompareOperator.notEqual,
      'lt' => CompareOperator.lessThan,
      'lteq' => CompareOperator.lessThanOrEqual,
      'gt' => CompareOperator.greaterThan,
      'gteq' => CompareOperator.greaterThanOrEqual,
      'in' => CompareOperator.contains,
      'notin' => CompareOperator.notContains,
      // TODO(expressions): Update error message.
      _ => throw UnsupportedError(symbol),
    };
  }
}

final class Operand extends Helper {
  const new({required this.operator, required this.value});

  final CompareOperator operator;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOperand(this, context);
  }

  @override
  Operand copyWith({CompareOperator? operator, Expression? value}) {
    return Operand(
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'operator': operator.symbol,
      'value': value.toJson(),
    };
  }
}

final class Compare extends Expression {
  const new({required this.value, this.operands = const <Operand>[]});

  final Expression value;

  final List<Operand> operands;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
    yield* operands;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
  }

  @override
  Compare copyWith({Expression? value, List<Operand>? operands}) {
    return Compare(
      value: value ?? this.value,
      operands: operands ?? this.operands,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Compare',
      'value': value.toJson(),
      'operands': operands.toJson(),
    };
  }
}

enum UnaryOperator {
  plus('+'),
  minus('-'),
  not('not');

  new(this.symbol);

  final String symbol;

  static UnaryOperator parse(String symbol) {
    return switch (symbol) {
      '+' => UnaryOperator.plus,
      '-' => UnaryOperator.minus,
      'not' => UnaryOperator.not,
      // TODO(expressions): Update error message.
      _ => throw UnsupportedError(symbol),
    };
  }
}

final class Unary extends Expression {
  const new({required this.operator, required this.value});

  final UnaryOperator operator;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield value;
  }

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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Unary',
      'operator': operator.symbol,
      'value': value.toJson(),
    };
  }
}

abstract final class Binary<E extends Enum> extends Expression {
  const new({required this.operator, required this.left, required this.right});

  final E operator;

  final Expression left;

  final Expression right;

  @override
  Iterable<Node> get childNodes sync* {
    yield left;
    yield right;
  }

  @override
  Binary<E> copyWith({E? operator, Expression? left, Expression? right});
}

enum ScalarOperator {
  power('**'),
  module('%'),
  floorDivision('~/'),
  division('/'),
  multiple('*'),
  minus('-'),
  plus('+');

  new(this.symbol);

  final String symbol;

  static ScalarOperator parse(String symbol) {
    return switch (symbol) {
      '**' => ScalarOperator.power,
      '%' => ScalarOperator.module,
      '~/' => ScalarOperator.floorDivision,
      '/' => ScalarOperator.division,
      '*' => ScalarOperator.multiple,
      '-' => ScalarOperator.minus,
      '+' => ScalarOperator.plus,
      // TODO(expressions): Update error message.
      _ => throw UnsupportedError(symbol),
    };
  }
}

final class Scalar extends Binary<ScalarOperator> {
  const new({
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Scalar',
      'operator': operator.symbol,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}

enum LogicalOperator { or, and }

final class Logical extends Binary<LogicalOperator> {
  const new({
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Logical',
      'operator': operator.name,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}
