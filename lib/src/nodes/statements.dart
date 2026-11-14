part of '/src/nodes.dart';

abstract interface class ImportContext {
  bool get withContext;
}

final class Extends extends Statement {
  const new({required this.template});

  final Expression template;

  @override
  Iterable<Node> get childNodes sync* {
    yield template;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExtends(this, context);
  }

  @override
  Extends copyWith({Expression? template}) {
    return Extends(template: template ?? this.template);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Extends', 'template': template.toJson()};
  }
}

final class For extends Statement {
  new({
    required this.target,
    required this.iterable,
    this.test,
    this.recursive = false,
    required this.nodes,
    this.elseNodes,
  });

  final Expression target;

  final Expression iterable;

  final Expression? test;

  final bool recursive;

  final List<Node> nodes;

  final List<Node>? elseNodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield target;
    yield iterable;

    if (test case var test?) {
      yield test;
    }

    yield* nodes;

    if (elseNodes case var elseNodes?) {
      yield* elseNodes;
    }
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFor(this, context);
  }

  @override
  For copyWith({
    Expression? target,
    Expression? iterable,
    Expression? test,
    bool? recursive,
    List<Node>? nodes,
    List<Node>? elseNodes,
  }) {
    return For(
      target: target ?? this.target,
      iterable: iterable ?? this.iterable,
      test: test ?? this.test,
      recursive: recursive ?? this.recursive,
      nodes: nodes ?? this.nodes,
      elseNodes: elseNodes ?? this.elseNodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'For',
      'target': target.toJson(),
      'iterable': iterable.toJson(),
      'test': test?.toJson(),
      'recursive': recursive,
      'nodes': nodes.toJson(),
      'elseNodes': elseNodes?.toJson(),
    };
  }
}

final class If extends Statement {
  const new({
    required this.test,
    required this.nodes,
    this.elseIfNodes,
    this.elseNodes,
  });

  final Expression test;

  final List<Node> nodes;

  final List<If>? elseIfNodes;

  final List<Node>? elseNodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield test;
    yield* nodes;

    if (elseIfNodes case var elseIfNodes?) {
      yield* elseIfNodes;
    }

    if (elseNodes case var elseNodes?) {
      yield* elseNodes;
    }
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  If copyWith({
    Expression? test,
    List<Node>? nodes,
    List<If>? elseIfNodes,
    List<Node>? elseNodes,
  }) {
    return If(
      test: test ?? this.test,
      nodes: nodes ?? this.nodes,
      elseIfNodes: elseIfNodes ?? this.elseIfNodes,
      elseNodes: elseNodes ?? this.elseNodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'If',
      'test': test.toJson(),
      'nodes': nodes.toJson(),
      'elseIfNodes': elseIfNodes?.toJson(),
      'elseNodes': elseNodes?.toJson(),
    };
  }
}

typedef MacroFunction = String Function(
  List<Object?> positional,
  Map<Symbol, Object?> named,
);

typedef MacroSignature = ({
  List<Expression> arguments,
  List<Expression> defaults,
});

final class Named extends Helper {
  const new({required this.argument, required this.defaultValue});

  final Expression argument;

  final Expression defaultValue;

  @override
  Iterable<Node> get childNodes sync* {
    yield argument;
    yield defaultValue;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNamed(this, context);
  }

  @override
  Named copyWith({Expression? argument, Expression? defaultValue}) {
    return Named(
      argument: argument ?? this.argument,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Named',
      'argument': argument.toJson(),
      'defaultValue': defaultValue.toJson(),
    };
  }
}

// TODO(nodes): change argument type to [String].
abstract final class MacroCall extends Statement {
  const new({
    this.positional = const <Expression>[],
    this.named = const <Named>[],
    required this.nodes,
  });

  final List<Expression> positional;

  // TODO(nodes): split arguments and defaults.
  final List<Named> named;

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* positional;
    yield* named;
    yield* nodes;
  }

  @override
  MacroCall copyWith({
    List<Expression>? positional,
    List<Named>? named,
    List<Node>? nodes,
  });
}

final class Macro extends MacroCall {
  const new({
    required this.name,
    super.positional,
    super.named,
    required super.nodes,
  });

  final String name;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMacro(this, context);
  }

  @override
  Macro copyWith({
    String? name,
    List<Expression>? positional,
    List<Named>? named,
    List<Node>? nodes,
  }) {
    return Macro(
      name: name ?? this.name,
      positional: positional ?? this.positional,
      named: named ?? this.named,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Macro',
      'name': name,
      'positional': positional.toJson(),
      'named': named.toJson(),
      'nodes': nodes.toJson(),
    };
  }
}

final class CallBlock extends MacroCall {
  new({
    required this.call,
    super.positional,
    super.named,
    required super.nodes,
  });

  final Call call;

  @override
  Iterable<Node> get childNodes sync* {
    yield call;
    yield* super.childNodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCallBlock(this, context);
  }

  @override
  CallBlock copyWith({
    Call? call,
    List<Expression>? positional,
    List<Named>? named,
    List<Node>? nodes,
  }) {
    return CallBlock(
      call: call ?? this.call,
      positional: positional ?? this.positional,
      named: named ?? this.named,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'CallBlock',
      'call': call.toJson(),
      'positional': positional.toJson(),
      'named': named.toJson(),
      'nodes': nodes.toJson(),
    };
  }
}

final class FilterBlock extends Statement {
  const new({required this.filter, required this.nodes});

  final Filter filter;

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield filter;
    yield* nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  FilterBlock copyWith({Filter? filter, List<Node>? nodes}) {
    return FilterBlock(
      filter: filter ?? this.filter,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'FilterBlock',
      'filter': filter.toJson(),
      'nodes': nodes.toJson(),
    };
  }
}

final class With extends Statement {
  const new({required this.targets, required this.values, required this.nodes});

  final List<Expression> targets;

  final List<Expression> values;

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* targets;
    yield* values;
    yield* nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  With copyWith({
    List<Expression>? targets,
    List<Expression>? values,
    List<Node>? nodes,
  }) {
    return With(
      targets: targets ?? this.targets,
      values: values ?? this.values,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'With',
      'targets': targets.toJson(),
      'values': values.toJson(),
      'nodes': nodes.toJson(),
    };
  }
}

final class Block extends Statement {
  const new({
    required this.name,
    required this.scoped,
    required this.required,
    required this.nodes,
  });

  final String name;

  final bool scoped;

  final bool required;

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* nodes;
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
    List<Node>? nodes,
  }) {
    return Block(
      name: name ?? this.name,
      scoped: scoped ?? this.scoped,
      required: required ?? this.required,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Block',
      'name': name,
      'scoped': scoped,
      'required': required,
      'nodes': nodes.toJson(),
    };
  }
}

final class Include extends Statement implements ImportContext {
  const new({
    required this.template,
    this.ignoreMissing = false,
    this.withContext = true,
  });

  final Expression template;

  final bool ignoreMissing;

  @override
  final bool withContext;

  @override
  Iterable<Node> get childNodes sync* {
    yield template;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitInclude(this, context);
  }

  @override
  Include copyWith({
    Expression? template,
    bool? ignoreMissing,
    bool? withContext,
  }) {
    return Include(
      template: template ?? this.template,
      ignoreMissing: ignoreMissing ?? this.ignoreMissing,
      withContext: withContext ?? this.withContext,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Include',
      'template': template.toJson(),
      'ignoreMissing': ignoreMissing,
      'withContext': withContext,
    };
  }
}

final class Import extends Statement implements ImportContext {
  const new({
    required this.template,
    required this.target,
    this.withContext = true,
  });

  final Expression template;

  final String target;

  @override
  final bool withContext;

  @override
  Iterable<Node> get childNodes sync* {
    yield template;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitImport(this, context);
  }

  @override
  Import copyWith({Expression? template, String? target, bool? withContext}) {
    return Import(
      template: template ?? this.template,
      target: target ?? this.target,
      withContext: withContext ?? this.withContext,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Import',
      'template': template.toJson(),
      'target': target,
      'withContext': withContext,
    };
  }
}

final class FromImport extends Statement implements ImportContext {
  const new({
    required this.template,
    required this.names,
    this.withContext = true,
  });

  final Expression template;

  final List<(String, String?)> names;

  @override
  final bool withContext;

  @override
  Iterable<Node> get childNodes sync* {
    yield template;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFromImport(this, context);
  }

  @override
  FromImport copyWith({
    Expression? template,
    List<(String, String?)>? names,
    bool? withContext,
  }) {
    return FromImport(
      template: template ?? this.template,
      names: names ?? this.names,
      withContext: withContext ?? this.withContext,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'FromImport',
      'template': template.toJson(),
      'names': <String, String?>{for (var (name, alias) in names) name: alias},
      'withContext': withContext,
    };
  }
}

final class Do extends Statement {
  new({required this.expressions});

  final List<Expression> expressions;

  @override
  Iterable<Node> get childNodes sync* {
    yield* expressions;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  Do copyWith({List<Expression>? expressions}) {
    return Do(expressions: expressions ?? this.expressions);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Do',
      'expressions': expressions.toJson(),
    };
  }
}

final class TryCatch extends Statement {
  new({required this.nodes, this.exception, required this.catchNodes});

  final List<Node> nodes;

  // TODO(nodes): find better name. String?
  final Name? exception;

  final List<Node> catchNodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* nodes;

    if (exception case var exception?) {
      yield exception;
    }

    yield* catchNodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTryCatch(this, context);
  }

  @override
  TryCatch copyWith({
    List<Node>? nodes,
    Name? exception,
    List<Node>? catchNodes,
  }) {
    return TryCatch(
      nodes: nodes ?? this.nodes,
      exception: exception ?? this.exception,
      catchNodes: catchNodes ?? this.catchNodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'TryCatch',
      'body': nodes.toJson(),
      'exception': exception?.toJson(),
      'catchNodes': catchNodes.toJson(),
    };
  }
}

final class Assign extends Statement {
  const new({required this.target, required this.value});

  final Expression target;

  final Expression value;

  @override
  Iterable<Node> get childNodes sync* {
    yield target;
    yield value;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssign(this, context);
  }

  @override
  Assign copyWith({Expression? target, Expression? value}) {
    return Assign(target: target ?? this.target, value: value ?? this.value);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Assign',
      'target': target.toJson(),
      'value': value.toJson(),
    };
  }
}

final class AssignBlock extends Statement {
  new({required this.target, this.filter, required this.nodes});

  final Expression target;

  final Filter? filter;

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield target;

    if (filter case var filter?) {
      yield filter;
    }

    yield* nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  AssignBlock copyWith({
    Expression? target,
    Filter? filter,
    List<Node>? nodes,
  }) {
    return AssignBlock(
      target: target ?? this.target,
      filter: filter ?? this.filter,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'AssignBlock',
      'target': target.toJson(),
      'filter': filter?.toJson(),
      'nodes': nodes.toJson(),
    };
  }
}
