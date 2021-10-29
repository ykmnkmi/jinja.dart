part of '../nodes.dart';

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
    return 'Extends($path)';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body,
      {this.orElse, this.test, this.recursive = false})
      : hasLoop = false {
    void visitor(Node node) {
      if (node is Name && node.name == 'loop') {
        hasLoop = true;
        return;
      }

      node.visitChildrens(visitor);
    }

    visitChildrens(visitor);
  }

  Expression target;

  Expression iterable;

  Node body;

  bool hasLoop;

  Node? orElse;

  Expression? test;

  bool recursive;

  @override
  List<Node> get childrens {
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
    var result = 'For';

    if (recursive) {
      result = '$result.recursive';
    }

    result = '$result($target, $iterable';

    if (test != null) {
      result = '$result, $test';
    }

    result = '$result, $body';

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class If extends Statement {
  If(this.test, this.body, {this.orElse});

  Expression test;

  Node body;

  Node? orElse;

  @override
  List<Node> get childrens {
    return <Node>[test, body, if (orElse != null) orElse!];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  String toString() {
    var result = 'If($test, $body';

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class FilterBlock extends Statement {
  FilterBlock(this.filters, this.body);

  List<Filter> filters;

  Node body;

  @override
  List<Node> get childrens {
    return <Node>[...filters, body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  String toString() {
    return 'FilterBlock($filters, $body)';
  }
}

class With extends Statement {
  With(this.targets, this.values, this.body);

  List<Expression> targets;

  List<Expression> values;

  Node body;

  @override
  List<Node> get childrens {
    return <Node>[...targets, ...values, body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  String toString() {
    return 'With($targets, $values, $body)';
  }
}

class Block extends Statement {
  Block(this.name, this.scoped, this.required, this.body) : hasSuper = false {
    void visitor(Node node) {
      if (node is Name && node.name == 'super') {
        hasSuper = true;
        return;
      }

      node.visitChildrens(visitor);
    }

    visitChildrens(visitor);
  }

  String name;

  bool scoped;

  bool required;

  bool hasSuper;

  Node body;

  @override
  List<Node> get childrens {
    return <Node>[body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBlock(this, context);
  }

  @override
  String toString() {
    var result = 'Block($name';

    if (scoped) {
      result = '$result, scoped';
    }

    if (hasSuper) {
      result = '$result, super';
    }

    return '$result, $body)';
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
    var prefix = 'Include';

    if (withContext) {
      prefix = '${prefix}withContext';
    }

    return '$prefix($template)';
  }
}

class Do extends Statement {
  Do(this.expression);

  Expression expression;

  @override
  List<Node> get childrens {
    return <Node>[expression];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  String toString() {
    return 'Do($expression)';
  }
}

class Assign extends Statement {
  Assign(this.target, this.value);

  Expression target;

  Expression value;

  @override
  List<Node> get childrens {
    return <Node>[target, value];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssign(this, context);
  }

  @override
  String toString() {
    return 'Assign($target, $value)';
  }
}

class AssignBlock extends Statement {
  AssignBlock(this.target, this.body, [this.filters]);

  Expression target;

  Node body;

  List<Filter>? filters;

  @override
  List<Node> get childrens {
    return <Node>[target, body, ...?filters];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  String toString() {
    var result = 'AssignBlock($target, $body';

    if (filters != null && filters!.isNotEmpty) {
      result = '$result, $filters';
    }

    return '$result)';
  }
}

class ScopedContextModifier extends Statement {
  ScopedContextModifier(this.options, this.body);

  Map<String, Expression> options;

  Node body;

  @override
  List<Node> get childrens {
    return <Node>[body, ...options.values];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitScopedContextModifier(this, context);
  }

  @override
  String toString() {
    return 'ScopedContextModifier($options, $body)';
  }
}

class Scope extends Statement {
  Scope(this.modifier);

  ScopedContextModifier modifier;

  @override
  List<Node> get childrens {
    return <Node>[modifier];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitScope(this, context);
  }

  @override
  String toString() {
    return 'Scope($modifier)';
  }
}
