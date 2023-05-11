part of '../nodes.dart';

abstract class ImportContext {
  bool get withContext;
}

abstract class Statement extends Node {
  const Statement();
}

class Extends extends Statement {
  const Extends({required this.path});

  final String path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExtends(this, context);
  }

  @override
  Extends copyWith({String? path}) {
    return Extends(path: path ?? this.path);
  }

  @override
  String toString() {
    return 'Extends ($path)';
  }
}

class For extends Statement {
  For({
    required this.target,
    required this.iterable,
    required this.body,
    this.test,
    this.orElse = const <Node>[],
    this.recursive = false,
  });

  final Expression target;

  final Expression iterable;

  final List<Node> body;

  final Expression? test;

  final List<Node> orElse;

  final bool recursive;

  @override
  List<Node> get children {
    return <Node>[
      target,
      iterable,
      ...body,
      if (test != null) test!,
      ...orElse,
    ];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFor(this, context);
  }

  @override
  For copyWith({
    Expression? target,
    Expression? iterable,
    List<Node>? body,
    Expression? test = defaultExpression,
    List<Node>? orElse,
    bool? recursive,
  }) {
    return For(
      target: target ?? this.target,
      iterable: iterable ?? this.iterable,
      body: body ?? this.body,
      test: test == defaultExpression ? this.test : test,
      orElse: orElse ?? this.orElse,
      recursive: recursive ?? this.recursive,
    );
  }

  @override
  String toString() {
    var result = 'For ($target, $iterable';

    if (test != null) {
      result = '$result, $test';
    }

    if (recursive) {
      result = '$result, recursive';
    }

    result = '$result) { $body }';

    if (orElse.isEmpty) {
      return result;
    }

    return '$result Else $orElse';
  }
}

class If extends Statement {
  const If({
    required this.test,
    required this.body,
    this.orElse = const <Node>[],
  });

  final Expression test;

  final List<Node> body;

  final List<Node> orElse;

  @override
  List<Node> get children {
    return <Node>[test, ...body, ...orElse];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  If copyWith({
    Expression? test,
    List<Node>? body,
    List<Node>? orElse,
  }) {
    return If(
      test: test ?? this.test,
      body: body ?? this.body,
      orElse: orElse ?? this.orElse,
    );
  }

  @override
  String toString() {
    if (orElse.isEmpty) {
      return 'If ($test) { $body }';
    }

    return 'If ($test) { $body } Else $orElse';
  }
}

typedef MacroSignature = ({
  List<Expression> arguments,
  List<Expression> defaults,
});

abstract class MacroCall extends Statement {
  const MacroCall({
    this.arguments = const <Expression>[],
    this.defaults = const <Expression>[],
    required this.body,
  });

  final List<Expression> arguments;

  final List<Expression> defaults;

  final List<Node> body;

  @override
  MacroCall copyWith({
    List<Expression>? arguments,
    List<Expression>? defaults,
    List<Node>? body,
  });
}

class Macro extends MacroCall {
  const Macro({
    required this.name,
    super.arguments,
    super.defaults,
    required super.body,
  });

  final String name;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMacro(this, context);
  }

  @override
  Macro copyWith({
    String? name,
    List<Expression>? arguments,
    List<Expression>? defaults,
    List<Node>? body,
  }) {
    return Macro(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      defaults: defaults ?? this.defaults,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'Macro ($name, $arguments, $defaults) { $body }';
  }
}

class CallBlock extends MacroCall {
  CallBlock({
    required this.call,
    super.arguments,
    super.defaults,
    required super.body,
  });

  final Expression call;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCallBlock(this, context);
  }

  @override
  CallBlock copyWith({
    Expression? call,
    List<Expression>? arguments,
    List<Expression>? defaults,
    List<Node>? body,
  }) {
    return CallBlock(
      call: call ?? this.call,
      arguments: arguments ?? this.arguments,
      defaults: defaults ?? this.defaults,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'CallBlock ($call, $arguments, $defaults) { $body }';
  }
}

class FilterBlock extends Statement {
  const FilterBlock({required this.filters, required this.body});

  final List<Filter> filters;

  final List<Node> body;

  @override
  List<Node> get children {
    return <Node>[...filters, ...body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  FilterBlock copyWith({List<Filter>? filters, List<Node>? body}) {
    return FilterBlock(
      filters: filters ?? this.filters,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'FilterBlock ($filters) { $body }';
  }
}

class With extends Statement {
  const With({
    required this.targets,
    required this.values,
    required this.body,
  });

  final List<Expression> targets;

  final List<Expression> values;

  final List<Node> body;

  @override
  List<Node> get children {
    return <Node>[...targets, ...values, ...body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  With copyWith({
    List<Expression>? targets,
    List<Expression>? values,
    List<Node>? body,
  }) {
    return With(
      targets: targets ?? this.targets,
      values: values ?? this.values,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'With ($targets, $values) { $body }';
  }
}

class Block extends Statement {
  const Block({
    required this.name,
    required this.scoped,
    required this.required,
    required this.body,
  });

  final String name;

  final bool scoped;

  final bool required;

  final List<Node> body;

  @override
  List<Node> get children {
    return body;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBlock(this, context);
  }

  @override
  Block copyWith({
    String? name,
    bool? scoped,
    bool? required,
    List<Node>? body,
  }) {
    return Block(
      name: name ?? this.name,
      scoped: scoped ?? this.scoped,
      required: required ?? this.required,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    var result = 'Block ($name';

    if (scoped) {
      result = '$result, scoped';
    }

    return '$result) { $body }';
  }
}

class Include extends Statement implements ImportContext {
  const Include({required this.template, this.withContext = true});

  final String template;

  @override
  final bool withContext;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitInclude(this, context);
  }

  @override
  Include copyWith({String? template, bool? withContext}) {
    return Include(
      template: template ?? this.template,
      withContext: withContext ?? this.withContext,
    );
  }

  @override
  String toString() {
    var result = 'Include ($template';

    if (withContext) {
      result = '$result, withContext';
    }

    return '$result)';
  }
}

class Do extends Statement {
  Do({required this.expression});

  final Expression expression;

  @override
  List<Node> get children {
    return <Node>[expression];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  Do copyWith({Expression? expression}) {
    return Do(
      expression: expression ?? this.expression,
    );
  }

  @override
  String toString() {
    return 'Do ($expression)';
  }
}

class Assign extends Statement {
  const Assign({required this.target, required this.value});

  final Expression target;

  final Expression value;

  @override
  List<Node> get children {
    return <Node>[target, value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssign(this, context);
  }

  @override
  Assign copyWith({Expression? target, Expression? value}) {
    return Assign(
      target: target ?? this.target,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return 'Assign ($target, $value)';
  }
}

class AssignBlock extends Statement {
  AssignBlock({
    required this.target,
    this.filters = const <Filter>[],
    required this.body,
  });

  final Expression target;

  final List<Filter> filters;

  final List<Node> body;

  @override
  List<Node> get children {
    return <Node>[target, ...filters, ...body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  AssignBlock copyWith({
    Expression? target,
    List<Filter>? filters,
    List<Node>? body,
  }) {
    return AssignBlock(
      target: target ?? this.target,
      filters: filters ?? this.filters,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    var result = 'AssignBlock ($target';

    if (filters.isNotEmpty) {
      result = '$result, $filters';
    }

    return '$result) { $body }';
  }
}

class AutoEscape extends Statement {
  const AutoEscape({required this.value, required this.body});

  final Expression value;

  final List<Node> body;

  @override
  List<Node> get children {
    return <Node>[value, ...body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAutoEscape(this, context);
  }

  @override
  AutoEscape copyWith({
    Expression? value,
    List<Node>? body,
  }) {
    return AutoEscape(
      value: value ?? this.value,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'AutoEscape ($value) { $body }';
  }
}
