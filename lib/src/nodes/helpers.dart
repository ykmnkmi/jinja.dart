part of '../nodes.dart';

class Pair extends Helper {
  Pair(this.key, this.value);

  Expression key;

  Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitPair(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(key);
    visitor(value);
  }

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}

class Keyword extends Helper {
  Keyword(this.key, this.value);

  String key;

  Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitKeyword(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(value);
  }

  @override
  String toString() {
    return 'Keyword($key, $value)';
  }
}

class Operand extends Helper {
  Operand(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOperand(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(expression);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $expression)';
  }
}

class NameSpaceReference extends Helper implements CanAssign {
  NameSpaceReference(this.name, this.attribute);

  String name;

  String attribute;

  @override
  bool get canAssign {
    return true;
  }

  @override
  AssignContext get context {
    return AssignContext.store;
  }

  @override
  set context(AssignContext context) {
    throw UnsupportedError('only for store');
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitNameSpaceReference(this, context);
  }

  @override
  String toString() {
    return 'NamespaceReference($name, $attribute)';
  }
}
