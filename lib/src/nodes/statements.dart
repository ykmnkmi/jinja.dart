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
  For(this.target, this.iterable, this.nodes,
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

  List<Node> nodes;

  bool hasLoop;

  List<Node>? orElse;

  Test? test;

  bool recursive;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFor(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    target.apply(visitor);
    iterable.apply(visitor);
    nodes.forEach(visitor);
    orElse?.forEach(visitor);
    test?.apply(visitor);
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

    if (nodes.isNotEmpty) {
      result = '$result, $nodes';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class If extends Statement {
  If(this.test, this.nodes, {this.nextIf, this.orElse});

  Expression test;

  List<Node> nodes;

  If? nextIf;

  List<Node>? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    test.apply(visitor);
    nodes.forEach(visitor);
    nextIf?.apply(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'If($test, $nodes';

    if (nextIf != null) {
      result = '$result, next: $nextIf';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class FilterBlock extends Statement {
  FilterBlock(this.filters, this.nodes);

  List<Filter> filters;

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilterBlock(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    filters.forEach(visitor);
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'FilterBlock($filters, $nodes)';
  }
}

class With extends Statement {
  With(this.targets, this.values, this.nodes);

  List<Expression> targets;

  List<Expression> values;

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitWith(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    targets.forEach(visitor);
    values.forEach(visitor);
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'With($targets, $values, $nodes)';
  }
}

class Block extends Statement {
  Block(this.name, this.scoped, this.required, this.nodes) : hasSuper = false {
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

  List<Node> nodes;

  @override
  void visitChildrens(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBlock(this, context);
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
  Do(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDo(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'Do(${expressions.join(', ')})';
  }
}

class Assign extends Statement {
  Assign(this.target, this.value);

  Expression target;

  Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssign(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    target.apply(visitor);
    value.apply(visitor);
  }

  @override
  String toString() {
    return 'Assign($target, $value)';
  }
}

class AssignBlock extends Statement {
  AssignBlock(this.target, this.nodes, [this.filters]);

  Expression target;

  List<Node> nodes;

  List<Filter>? filters;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    target.apply(visitor);
    nodes.forEach(visitor);
    filters?.forEach(visitor);
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

abstract class ContextModifier extends Statement {}

class Scope extends Statement {
  Scope(this.modifier);

  ContextModifier modifier;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitScope(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    modifier.apply(visitor);
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
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitScopedContextModifier(this, context);
  }

  @override
  void visitChildrens(NodeVisitor visitor) {
    nodes.forEach(visitor);
    options.values.forEach(visitor);
  }

  @override
  String toString() {
    return 'ScopedContextModifier($options, $nodes)';
  }
}
