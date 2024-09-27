part of '../nodes.dart';

abstract interface class ImportContext {
  bool get withContext;
}

final class Extends extends Statement {
  const Extends({required this.template});

  final Expression template;

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
    return <String, Object?>{
      'class': 'Extends',
      'template': template.toJson(),
    };
  }
}

final class For extends Statement {
  For({
    required this.target,
    required this.iterable,
    this.test,
    this.recursive = false,
    required this.body,
    this.orElse,
  });

  final Expression target;

  final Expression iterable;

  final Expression? test;

  final bool recursive;

  final Node body;

  final Node? orElse;

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
    Node? body,
    Node? orElse,
  }) {
    return For(
      target: target ?? this.target,
      iterable: iterable ?? this.iterable,
      test: test ?? this.test,
      recursive: recursive ?? this.recursive,
      body: body ?? this.body,
      orElse: orElse ?? this.orElse,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (target case T target) {
      yield target;
    }

    yield* target.findAll<T>();

    if (iterable case T iterable) {
      yield iterable;
    }

    yield* iterable.findAll<T>();

    if (test case Expression test?) {
      if (test case T test) {
        yield test;
      }

      yield* test.findAll<T>();
    }

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();

    if (orElse case Node orElse?) {
      if (orElse case T orElse) {
        yield orElse;
      }

      yield* orElse.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'For',
      'target': target.toJson(),
      'iterable': iterable.toJson(),
      if (test case var test?) 'test': test.toJson(),
      if (recursive) 'recursive': recursive,
      'body': body.toJson(),
      if (orElse case var orElse?) 'orElse': orElse.toJson(),
    };
  }
}

final class If extends Statement {
  const If({
    required this.test,
    required this.body,
    this.orElse,
  });

  final Expression test;

  final Node body;

  final Node? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  If copyWith({
    Expression? test,
    Node? body,
    Node? orElse,
  }) {
    return If(
      test: test ?? this.test,
      body: body ?? this.body,
      orElse: orElse ?? this.orElse,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (test case T test) {
      yield test;
    }

    yield* test.findAll<T>();

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();

    if (orElse case Node orElse?) {
      if (orElse case T orElse) {
        yield orElse;
      }

      yield* orElse.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'If',
      'test': test.toJson(),
      'body': body.toJson(),
      if (orElse case var orElse?) 'orElse': orElse.toJson(),
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

// TODO(nodes): change argument to String
abstract final class MacroCall extends Statement {
  const MacroCall({
    this.varargs = false,
    this.kwargs = false,
    this.positional = const <Expression>[],
    this.named = const <(Expression, Expression)>[],
    required this.body,
  });

  final bool varargs;

  final bool kwargs;

  final List<Expression> positional;

  // TODO(nodes): split arguments and defaults
  final List<(Expression, Expression)> named;

  final Node body;

  @override
  MacroCall copyWith({
    List<Expression>? positional,
    List<(Expression, Expression)>? named,
    Node? body,
  });

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var (argument, defaultValue) in named) {
      if (argument case T argument) {
        yield argument;
      }

      yield* argument.findAll<T>();

      if (defaultValue case T defaultValue) {
        yield defaultValue;
      }

      yield* defaultValue.findAll<T>();
    }

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }
}

final class Macro extends MacroCall {
  const Macro({
    required this.name,
    super.varargs,
    super.kwargs,
    this.caller = false,
    super.positional,
    super.named,
    required super.body,
  });

  final String name;

  final bool caller;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMacro(this, context);
  }

  @override
  Macro copyWith({
    String? name,
    List<Expression>? positional,
    List<(Expression, Expression)>? named,
    bool? varargs,
    bool? kwargs,
    bool? caller,
    Node? body,
  }) {
    return Macro(
      name: name ?? this.name,
      positional: positional ?? this.positional,
      named: named ?? this.named,
      varargs: varargs ?? this.varargs,
      kwargs: kwargs ?? this.kwargs,
      caller: caller ?? this.caller,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Macro',
      if (varargs) 'varargs': varargs,
      if (kwargs) 'kwargs': kwargs,
      if (caller) 'caller': caller,
      'positional': <Map<String, Object?>>[
        for (var argument in positional) argument.toJson(),
      ],
      'named': <Map<String, Object?>>[
        for (var (argument, defaultValue) in named)
          <String, Object?>{
            'argument': argument.toJson(),
            'defaultValue': defaultValue.toJson(),
          },
      ],
      'body': body.toJson(),
    };
  }
}

final class CallBlock extends MacroCall {
  CallBlock({
    required this.call,
    super.varargs,
    super.kwargs,
    super.positional,
    super.named,
    required super.body,
  });

  final Call call;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCallBlock(this, context);
  }

  @override
  CallBlock copyWith({
    Call? call,
    List<Expression>? positional,
    List<(Expression, Expression)>? named,
    Node? body,
  }) {
    return CallBlock(
      call: call ?? this.call,
      positional: positional ?? this.positional,
      named: named ?? this.named,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (call case T call) {
      yield call;
    }

    yield* call.findAll<T>();
    yield* super.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'CallBlock',
      if (varargs) 'varargs': varargs,
      if (kwargs) 'kwargs': kwargs,
      'positional': <Map<String, Object?>>[
        for (var argument in positional) argument.toJson(),
      ],
      'named': <Map<String, Object?>>[
        for (var (argument, defaultValue) in named)
          <String, Object?>{
            'argument': argument.toJson(),
            'defaultValue': defaultValue.toJson(),
          },
      ],
      'body': body.toJson(),
    };
  }
}

final class FilterBlock extends Statement {
  const FilterBlock({required this.filters, required this.body});

  final List<Filter> filters;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  FilterBlock copyWith({List<Filter>? filters, Node? body}) {
    return FilterBlock(
      filters: filters ?? this.filters,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var filter in filters) {
      if (filter case T filter) {
        yield filter;
      }

      yield* filter.findAll<T>();
    }

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'FilterBlock',
      'filters': <Map<String, Object?>>[
        for (var filter in filters) filter.toJson(),
      ],
      'body': body.toJson(),
    };
  }
}

final class With extends Statement {
  const With({
    required this.targets,
    required this.values,
    required this.body,
  });

  final List<Expression> targets;

  final List<Expression> values;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  With copyWith({
    List<Expression>? targets,
    List<Expression>? values,
    Node? body,
  }) {
    return With(
      targets: targets ?? this.targets,
      values: values ?? this.values,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var target in targets) {
      if (target case T target) {
        yield target;
      }

      yield* target.findAll<T>();
    }

    for (var value in values) {
      if (value case T vaue) {
        yield vaue;
      }

      yield* value.findAll<T>();
    }

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'With',
      'targets': <Map<String, Object?>>[
        for (var target in targets) target.toJson(),
      ],
      'values': <Map<String, Object?>>[
        for (var value in values) value.toJson(),
      ],
      'body': body.toJson(),
    };
  }
}

final class Block extends Statement {
  const Block({
    required this.name,
    required this.scoped,
    required this.required,
    required this.body,
  });

  final String name;

  final bool scoped;

  final bool required;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBlock(this, context);
  }

  @override
  Block copyWith({
    String? name,
    bool? scoped,
    bool? required,
    Node? body,
  }) {
    return Block(
      name: name ?? this.name,
      scoped: scoped ?? this.scoped,
      required: required ?? this.required,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Block',
      'name': name,
      if (scoped) 'scoped': scoped,
      if (required) 'required': required,
      'body': body.toJson(),
    };
  }
}

final class Include extends Statement implements ImportContext {
  const Include({
    required this.template,
    this.ignoreMissing = false,
    this.withContext = true,
  });

  final Expression template;

  final bool ignoreMissing;

  @override
  final bool withContext;

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
      'template': template,
      if (ignoreMissing) 'ignoreMissing': ignoreMissing,
      if (withContext) 'withContext': withContext,
    };
  }
}

final class Import extends Statement implements ImportContext {
  const Import({
    required this.template,
    required this.target,
    this.withContext = true,
  });

  final Expression template;

  final String target;

  @override
  final bool withContext;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitImport(this, context);
  }

  @override
  Import copyWith({
    Expression? template,
    String? target,
    bool? withContext,
  }) {
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
      'template': template,
      'target': target,
      if (withContext) 'withContext': withContext,
    };
  }
}

final class FromImport extends Statement implements ImportContext {
  const FromImport({
    required this.template,
    required this.names,
    this.withContext = true,
  });

  final Expression template;

  final List<(String, String?)> names;

  @override
  final bool withContext;

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
      'template': template,
      'names': <String, String?>{for (var (name, alias) in names) name: alias},
      if (withContext) 'withContext': withContext,
    };
  }
}

final class Do extends Statement {
  Do({required this.value});

  final Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  Do copyWith({Expression? value}) {
    return Do(
      value: value ?? this.value,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T vaue) {
      yield vaue;
    }

    yield* value.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Do',
      'value': value,
    };
  }
}

final class Assign extends Statement {
  const Assign({required this.target, required this.value});

  final Expression target;

  final Expression value;

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
  Iterable<T> findAll<T extends Node>() sync* {
    if (target case T target) {
      yield target;
    }

    yield* target.findAll<T>();

    if (value case T vaue) {
      yield vaue;
    }

    yield* value.findAll<T>();
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
  AssignBlock({
    required this.target,
    this.filters = const <Filter>[],
    required this.body,
  });

  final Expression target;

  final List<Filter> filters;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  AssignBlock copyWith({
    Expression? target,
    List<Filter>? filters,
    Node? body,
  }) {
    return AssignBlock(
      target: target ?? this.target,
      filters: filters ?? this.filters,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (target case T target) {
      yield target;
    }

    yield* target.findAll<T>();

    for (var filter in filters) {
      if (filter case T filter) {
        yield filter;
      }

      yield* filter.findAll<T>();
    }

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'AssignBlock',
      'target': target.toJson(),
      'filters': <Map<String, Object?>>[
        for (var filter in filters) filter.toJson(),
      ],
      'body': body.toJson(),
    };
  }
}
