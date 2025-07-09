part of '../nodes.dart';

enum AssignContext {
  load,
  store,
  parameter,
}

final class Name extends Expression {
  const Name({required this.name, this.context = AssignContext.load});

  const Name.store({required String name})
      : this(name: name, context: AssignContext.store);

  const Name.parameter({required String name})
      : this(name: name, context: AssignContext.parameter);

  final String name;

  final AssignContext context;

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

final class NamespaceRef extends Expression {
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'NamespaceRef',
      'name': name,
      'attribute': attribute,
    };
  }
}

abstract base class Literal extends Expression {
  const Literal();
}

final class Constant extends Literal {
  const Constant({required this.value});

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
    return <String, Object?>{
      'class': 'Constant',
      'value': value,
    };
  }
}

final class Tuple extends Literal {
  const Tuple({required this.values});

  final List<Expression> values;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTuple(this, context);
  }

  @override
  Tuple copyWith({List<Expression>? values}) {
    return Tuple(
      values: values ?? this.values,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var value in values) {
      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Tuple',
      'values': <Map<String, Object?>>[
        for (var value in values) value.toJson(),
      ],
    };
  }
}

final class Array extends Literal {
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
  Iterable<T> findAll<T extends Node>() sync* {
    for (var value in values) {
      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Array',
      'values': <Map<String, Object?>>[
        for (var value in values) value.toJson(),
      ],
    };
  }
}

typedef Pair = ({
  Expression key,
  Expression value,
});

final class Dict extends Literal {
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
  Iterable<T> findAll<T extends Node>() sync* {
    for (var (:key, :value) in pairs) {
      if (key case T key) {
        yield key;
      }

      yield* key.findAll<T>();

      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Dict',
      'values': <Map<String, Object?>>[
        for (var (:key, :value) in pairs)
          <String, Object?>{
            'key': key.toJson(),
            'value': value.toJson(),
          },
      ],
    };
  }
}

final class Condition extends Expression {
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
    Expression? falseValue,
  }) {
    return Condition(
      test: test ?? this.test,
      trueValue: trueValue ?? this.trueValue,
      falseValue: falseValue ?? this.falseValue,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (test case T test) {
      yield test;
    }

    yield* test.findAll<T>();

    if (trueValue case T trueValue) {
      yield trueValue;
    }

    yield* trueValue.findAll<T>();

    if (falseValue case T falseValue) {
      yield falseValue;
    }

    if (falseValue case Expression falseValue?) {
      yield* falseValue.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Condition',
      'test': test.toJson(),
      'trueValue': trueValue.toJson(),
      if (falseValue case Expression falseValue?)
        'falseValue': falseValue.toJson(),
    };
  }
}

typedef Keyword = ({String key, Expression value});

typedef Parameters = (List<Object?>, Map<Symbol, Object?>);

final class Calling extends Expression {
  const Calling({
    this.arguments = const <Expression>[],
    this.keywords = const <Keyword>[],
  });

  final List<Expression> arguments;

  final List<Keyword> keywords;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCalling(this, context);
  }

  @override
  Calling copyWith({
    List<Expression>? arguments,
    List<Keyword>? keywords,
    Expression? dArguments,
    Expression? dKeywords,
  }) {
    return Calling(
      arguments: arguments ?? this.arguments,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var argument in arguments) {
      if (argument case T argument) {
        yield argument;
      }

      yield* argument.findAll<T>();
    }

    for (var (key: _, :value) in keywords) {
      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Calling',
      'arguments': <Map<String, Object?>>[
        for (var argument in arguments) argument.toJson(),
      ],
      'keywords': <Map<String, Object?>>[
        for (var (:key, :value) in keywords)
          <String, Object?>{
            'key': key,
            'value': value.toJson(),
          },
      ],
    };
  }
}

final class Call extends Expression {
  const Call({
    required this.value,
    this.calling = const Calling(),
  });

  final Expression value;

  final Calling calling;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
  }

  @override
  Call copyWith({Expression? value, Calling? calling}) {
    return Call(
      value: value ?? this.value,
      calling: calling ?? this.calling,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();

    if (calling case T calling) {
      yield calling;
    }

    yield* calling.findAll<T>();
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (calling case T calling) {
      yield calling;
    }

    yield* calling.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Filter',
      'name': name,
      'calling': calling.toJson(),
    };
  }
}

final class Test extends Expression {
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (calling case T calling) {
      yield calling;
    }

    yield* calling.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Test',
      'name': name,
      'calling': calling.toJson(),
    };
  }
}

final class Item extends Expression {
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (key case T key) {
      yield key;
    }

    yield* key.findAll<T>();

    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
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
  const Slice({required this.value, required this.start, this.stop});

  final Expression value;

  final Expression? start;

  final Expression? stop;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSlice(this, context);
  }

  @override
  Slice copyWith({Expression? start, Expression? stop}) {
    return Slice(
      value: value,
      start: start ?? this.start,
      stop: stop ?? this.stop,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Slice',
      'start': start?.toJson(),
      'stop': stop?.toJson(),
      'value': value.toJson(),
    };
  }
}

final class Attribute extends Expression {
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
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
  Iterable<T> findAll<T extends Node>() sync* {
    for (var value in values) {
      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Concat',
      'values': <Map<String, Object?>>[
        for (var value in values) value.toJson(),
      ],
    };
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

  const CompareOperator(this.symbol);

  final String symbol;

  static CompareOperator parse(String operator) {
    return switch (operator) {
      'eq' => CompareOperator.equal,
      'ne' => CompareOperator.notEqual,
      'lt' => CompareOperator.lessThan,
      'lteq' => CompareOperator.lessThanOrEqual,
      'gt' => CompareOperator.greaterThan,
      'gteq' => CompareOperator.greaterThanOrEqual,
      'in' => CompareOperator.contains,
      'notin' => CompareOperator.notContains,
      // TODO(expressions): update error message
      _ => throw UnsupportedError(operator),
    };
  }
}

typedef Operand = (CompareOperator operator, Expression value);

final class Compare extends Expression {
  const Compare({
    required this.value,
    this.operands = const <Operand>[],
  });

  final Expression value;

  final List<Operand> operands;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
  }

  @override
  Compare copyWith({
    Expression? value,
    List<Operand>? operands,
  }) {
    return Compare(
      value: value ?? this.value,
      operands: operands ?? this.operands,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();

    for (var (_, value) in operands) {
      if (value case T value) {
        yield value;
      }

      yield* value.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Compare',
      'value': value.toJson(),
      'operands': <Map<String, Object?>>[
        for (var (operand, value) in operands)
          <String, Object?>{
            'operand': operand.symbol,
            'value': value.toJson(),
          },
      ],
    };
  }
}

enum UnaryOperator {
  plus('+'),
  minus('-'),
  not('not');

  const UnaryOperator(this.symbol);

  final String symbol;
}

final class Unary extends Expression {
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
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
  const Binary({
    required this.operator,
    required this.left,
    required this.right,
  });

  final E operator;

  final Expression left;

  final Expression right;

  @override
  Binary<E> copyWith({E? operator, Expression? left, Expression? right});

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (left case T left) {
      yield left;
    }

    yield* left.findAll<T>();

    if (right case T right) {
      yield right;
    }

    yield* right.findAll<T>();
  }
}

enum ScalarOperator {
  power('**'),
  module('%'),
  floorDivision('~/'),
  division('/'),
  multiple('*'),
  minus('-'),
  plus('+');

  const ScalarOperator(this.symbol);

  final String symbol;
}

final class Scalar extends Binary<ScalarOperator> {
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Scalar',
      'operator': operator.symbol,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}

enum LogicalOperator {
  or,
  and,
}

final class Logical extends Binary<LogicalOperator> {
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Logical',
      'operator': operator.name,
      'left': left.toJson(),
      'right': right.toJson(),
    };
  }
}
