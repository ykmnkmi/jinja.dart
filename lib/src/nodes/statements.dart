part of '../nodes.dart';

abstract class ImportContext {
  bool get withContext;
}

final class Extends extends Statement {
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
}

typedef MacroSignature = ({
  List<Expression> arguments,
  List<Expression> defaults,
});

abstract final class MacroCall extends Statement {
  const MacroCall({
    this.arguments = const <(Expression, Expression?)>[],
    required this.body,
  });

  // TODO(nodes): change argument to String
  // TODO(nodes): split arguments and defaults
  final List<(Expression, Expression?)> arguments;

  final Node body;

  @override
  MacroCall copyWith({
    List<(Expression, Expression?)>? arguments,
    Node? body,
  });

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    for (var (argument, default_) in arguments) {
      if (argument case T argument) {
        yield argument;
      }

      yield* argument.findAll<T>();

      if (default_ case Expression default_?) {
        if (default_ case T default_) {
          yield default_;
        }

        yield* default_.findAll<T>();
      }
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
    super.arguments,
    this.varargs = false,
    this.kwargs = false,
    this.caller = false,
    required super.body,
  });

  final String name;

  final bool varargs;

  final bool kwargs;

  final bool caller;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMacro(this, context);
  }

  @override
  Macro copyWith({
    String? name,
    List<(Expression, Expression?)>? arguments,
    bool? varargs,
    bool? kwargs,
    bool? caller,
    Node? body,
  }) {
    return Macro(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      varargs: varargs ?? this.varargs,
      kwargs: kwargs ?? this.kwargs,
      caller: caller ?? this.caller,
      body: body ?? this.body,
    );
  }
}

final class CallBlock extends MacroCall {
  CallBlock({
    required this.call,
    super.arguments,
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
    List<(Expression, Expression?)>? arguments,
    Node? body,
  }) {
    return CallBlock(
      call: call ?? this.call,
      arguments: arguments ?? this.arguments,
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
}

final class Include extends Statement implements ImportContext {
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
}

final class AutoEscape extends Statement {
  const AutoEscape({required this.value, required this.body});

  final Expression value;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAutoEscape(this, context);
  }

  @override
  AutoEscape copyWith({
    Expression? value,
    Node? body,
  }) {
    return AutoEscape(
      value: value ?? this.value,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T vaue) {
      yield vaue;
    }

    yield* value.findAll<T>();

    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }
}
