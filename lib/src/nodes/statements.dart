part of '../nodes.dart';

abstract class ImportContext {
  bool get withContext;

  set withContext(bool withContext);
}

abstract class Statement extends Node {}

class Extends extends Statement {
  Extends(this.path);

  String path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExtends(this, context);
  }

  @override
  String toString() {
    return 'Extends ($path)';
  }
}

class For extends Statement {
  For(
    this.target,
    this.iterable,
    this.body, {
    this.orElse,
    this.test,
    this.recursive = false,
  }) : hasLoop = false {
    for (var nameNode in findAll<Name>()) {
      if (nameNode.name == 'loop') {
        hasLoop = true;
        break;
      }
    }
  }

  Expression target;

  Expression iterable;

  Node body;

  bool hasLoop;

  Node? orElse;

  Expression? test;

  bool recursive;

  @override
  List<Node> get children {
    return <Node>[
      target,
      iterable,
      body,
      if (orElse != null) orElse!,
      if (test != null) test!,
    ];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFor(this, context);
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

    if (orElse == null) {
      return result;
    }

    return '$result Else $orElse';
  }
}

class If extends Statement {
  If(this.test, this.body, {this.orElse});

  Expression test;

  Node body;

  Node? orElse;

  @override
  List<Node> get children {
    return <Node>[test, body, if (orElse != null) orElse!];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  String toString() {
    if (orElse == null) {
      return 'If ($test) { $body }';
    }

    return 'If ($test) { $body } Else $orElse';
  }
}

abstract class MacroCall extends Statement {
  MacroCall({
    List<Expression>? arguments,
    List<Expression>? defaults,
    Node? body,
  })  : arguments = arguments ?? <Expression>[],
        defaults = defaults ?? <Expression>[],
        body = body ?? Data('');

  List<Expression> arguments;

  List<Expression> defaults;

  Node body;
}

class Macro extends MacroCall {
  Macro(
    this.name, {
    super.arguments,
    super.defaults,
    super.body,
  });

  String name;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMacro(this, context);
  }

  @override
  String toString() {
    return 'Macro ($name, $arguments, $defaults) { $body }';
  }
}

class CallBlock extends MacroCall {
  CallBlock(
    this.call, {
    super.arguments,
    super.defaults,
    super.body,
  });

  Expression call;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCallBlock(this, context);
  }

  @override
  String toString() {
    return 'CallBlock ($call, $arguments, $defaults) { $body }';
  }
}

class FilterBlock extends Statement {
  FilterBlock(this.filters, this.body);

  List<Filter> filters;

  Node body;

  @override
  List<Node> get children {
    return <Node>[...filters, body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  String toString() {
    return 'FilterBlock ($filters) { $body }';
  }
}

class With extends Statement {
  With(this.targets, this.values, this.body);

  List<Expression> targets;

  List<Expression> values;

  Node body;

  @override
  List<Node> get children {
    return <Node>[...targets, ...values, body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  String toString() {
    return 'With ($targets, $values) { $body }';
  }
}

class Block extends Statement {
  Block(this.name, this.scoped, this.required, this.body) : hasSuper = false {
    for (var nameNode in findAll<Name>()) {
      if (nameNode.name == 'super') {
        hasSuper = true;
        break;
      }
    }
  }

  String name;

  bool scoped;

  bool required;

  bool hasSuper;

  Node body;

  @override
  List<Node> get children {
    return <Node>[body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBlock(this, context);
  }

  @override
  String toString() {
    var result = 'Block ($name';

    if (scoped) {
      result = '$result, scoped';
    }

    if (hasSuper) {
      result = '$result, super';
    }

    return '$result) { $body }';
  }
}

class Include extends Statement implements ImportContext {
  Include(this.template, {this.withContext = true});

  String template;

  @override
  bool withContext;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitInclude(this, context);
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
  Do(this.expression);

  Expression expression;

  @override
  List<Node> get children {
    return <Node>[expression];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  String toString() {
    return 'Do ($expression)';
  }
}

class Assign extends Statement {
  Assign(this.target, this.value);

  Expression target;

  Expression value;

  @override
  List<Node> get children {
    return <Node>[target, value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssign(this, context);
  }

  @override
  String toString() {
    return 'Assign ($target, $value)';
  }
}

class AssignBlock extends Statement {
  AssignBlock(this.target, this.body, [this.filters]);

  Expression target;

  Node body;

  List<Filter>? filters;

  @override
  List<Node> get children {
    return <Node>[target, body, ...?filters];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  String toString() {
    var result = 'AssignBlock ($target';

    if (filters != null && filters!.isNotEmpty) {
      result = '$result, $filters';
    }

    return '$result) { $body }';
  }
}

class AutoEscape extends Statement {
  AutoEscape(this.value, this.body);

  Expression value;

  Node body;

  @override
  List<Node> get children {
    return <Node>[value, body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAutoEscape(this, context);
  }

  @override
  String toString() {
    return 'AutoEscape ($value) { $body }';
  }
}
