part of '../nodes.dart';

class Do extends Statement {
  Do(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitDo(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'Do(${expressions.join(', ')})';
  }
}

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOutput(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'Output(${nodes.join(', ')})';
  }
}

class Extends extends Statement {
  Extends(this.path);

  String path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitExtends(this, context);
  }

  @override
  String toString() {
    return 'Extends($path)';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body,
      {this.hasLoop = false, this.orElse, this.test, this.recursive = false});

  Expression target;

  Expression iterable;

  List<Node> body;

  bool hasLoop;

  List<Node>? orElse;

  Test? test;

  bool recursive;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFor(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    visitor(iterable);
    body.forEach(visitor);
    orElse?.forEach(visitor);
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

    if (body.isNotEmpty) {
      result = '$result, $body';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class If extends Statement {
  If(this.test, this.body, {this.nextIf, this.orElse});

  Expression test;

  List<Node> body;

  If? nextIf;

  List<Node>? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitIf(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(test);

    for (final node in body) {
      visitor(node);
    }

    nextIf?.visitChildNodes(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'If($test, $body';

    if (nextIf != null) {
      result = '$result, next: $nextIf';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class With extends Statement {
  With(this.targets, this.values, this.body);

  List<Expression> targets;

  List<Expression> values;

  List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitWith(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    targets.forEach(visitor);
    values.forEach(visitor);
    body.forEach(visitor);
  }

  @override
  String toString() {
    return 'With($targets, $values, $body)';
  }
}

class Block extends Statement {
  Block(this.name, this.scoped, this.required, this.hasSuper, this.nodes);

  String name;

  bool scoped;

  bool required;

  bool hasSuper;

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitBlock(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'Block';

    if (scoped) {
      result += '.scoped';
    }

    return '$result($name, ${nodes.join(', ')})';
  }
}

class Include extends Statement implements ImportContext {
  Include(this.template, {this.withContext = true});

  String template;

  @override
  bool withContext;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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

class Assign extends Statement {
  Assign(this.target, this.expression);

  Expression target;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAssign(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    visitor(expression);
  }

  @override
  String toString() {
    return 'Assign($target, $expression)';
  }
}

class AssignBlock extends Statement {
  AssignBlock(this.target, this.nodes, [this.filters]);

  Expression target;

  List<Node> nodes;

  List<Filter>? filters;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'AssignBlock($target, $nodes';

    if (filters != null && filters!.isNotEmpty) {
      result = '$result, $filters';
    }

    return '$result)';
  }
}

class Scope extends Statement {
  Scope(this.modifier);

  ContextModifier modifier;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitScope(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    modifier.visitChildNodes(visitor);
  }

  @override
  String toString() {
    return 'Scope($modifier)';
  }
}

class ScopedContextModifier extends ContextModifier {
  ScopedContextModifier(this.options, this.nodes);

  List<Node> nodes;

  Map<String, Expression> options;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitScopedContextModifier(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'ScopedContextModifier($options, $nodes)';
  }
}
