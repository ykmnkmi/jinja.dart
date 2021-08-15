part of '../nodes.dart';

enum AssignContext {
  load,
  store,
  parameter,
}

mixin CanAssign on Expression {
  bool get canAssign;

  AssignContext get context;

  set context(AssignContext context);
}

abstract class Callable {
  Expression? get expression;

  List<Expression>? get arguments;

  List<Keyword>? get keywordArguments;

  Expression? get dArguments;

  Expression? get dKeywordArguments;
}

class Name extends Expression with CanAssign {
  Name(this.name, {this.context = AssignContext.load, this.type});

  String name;

  String? type;

  @override
  AssignContext context;

  @override
  bool get canAssign {
    return context == AssignContext.store;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitName(this, context);
  }

  @override
  String toString() {
    return type == null ? 'Name($name)' : 'Name($name, $type)';
  }
}

class Concat extends Expression {
  Concat(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConcat(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'Concat($expressions)';
  }
}

class Attribute extends Expression {
  Attribute(this.attribute, this.expression);

  String attribute;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAttribute(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(expression);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $expression)';
  }
}

class Item extends Expression {
  Item(this.key, this.expression);

  Expression key;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitItem(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(key);
    visitor(expression);
  }

  @override
  String toString() {
    return 'Item($key, $expression)';
  }
}

class Slice extends Expression {
  factory Slice.fromList(List<Expression?> expressions) {
    assert(expressions.length <= 3);

    switch (expressions.length) {
      case 0:
        return Slice();
      case 1:
        return Slice(start: expressions[0]);
      case 2:
        return Slice(start: expressions[0], stop: expressions[1]);
      case 3:
        return Slice(
            start: expressions[0], stop: expressions[1], step: expressions[2]);
      default:
        throw TemplateRuntimeError();
    }
  }

  Slice({this.start, this.stop, this.step});

  Expression? start;

  Expression? stop;

  Expression? step;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSlice(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    final start = this.start;

    if (start != null) {
      visitor(start);
    }

    final stop = this.stop;

    if (stop != null) {
      visitor(stop);
    }

    final step = this.step;

    if (step != null) {
      visitor(step);
    }
  }

  @override
  String toString() {
    var result = 'Slice(';

    if (start != null) {
      result += 'start: $start';
    }

    if (stop != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'stop: $stop';
    }

    if (step != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'step: $step';
    }

    return result + ')';
  }
}

class Call extends Expression implements Callable {
  Call(
      {this.expression,
      this.arguments,
      this.keywordArguments,
      this.dArguments,
      this.dKeywordArguments});

  @override
  Expression? expression;

  @override
  List<Expression>? arguments;

  @override
  List<Keyword>? keywordArguments;

  @override
  Expression? dArguments;

  @override
  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    final expression = this.expression;

    if (expression != null) {
      visitor(expression);
    }

    final arguments = this.arguments;

    if (arguments != null) {
      arguments.forEach(visitor);
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null) {
      keywordArguments.forEach(visitor);
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      visitor(dArguments);
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      visitor(dKeywordArguments);
    }
  }

  @override
  String toString() {
    var result = 'Call(';
    var comma = false;

    if (expression != null) {
      result += '$expression';
      comma = true;
    }

    final arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      if (comma) {
        result += ', ';
      } else {
        comma = true;
      }

      result += arguments.join(', ');
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null && keywordArguments.isNotEmpty) {
      if (comma) {
        result += ', ';
      } else {
        comma = true;
      }

      result += keywordArguments.join(', ');
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      if (comma) {
        result += ', ';
      } else {
        comma = true;
      }

      result += '*$dArguments';
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      if (comma) {
        result += ', ';
      }

      result += '**$dKeywordArguments';
    }

    return result + ')';
  }
}

class Filter extends Expression implements Callable {
  Filter(this.name,
      {this.expression,
      this.arguments,
      this.keywordArguments,
      this.dArguments,
      this.dKeywordArguments});

  String name;

  @override
  Expression? expression;

  @override
  List<Expression>? arguments;

  @override
  List<Keyword>? keywordArguments;

  @override
  Expression? dArguments;

  @override
  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilter(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    final expression = this.expression;

    if (expression != null) {
      visitor(expression);
    }

    final arguments = this.arguments;

    if (arguments != null) {
      arguments.forEach(visitor);
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null) {
      keywordArguments.forEach(visitor);
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      visitor(dArguments);
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      visitor(dKeywordArguments);
    }
  }

  @override
  String toString() {
    var result = 'Filter(\'$name\'';

    if (expression != null) {
      result += ', $expression';
    }

    final arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      result += ', ';

      result += arguments.join(', ');
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null && keywordArguments.isNotEmpty) {
      result += keywordArguments.join(', ');
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      result += '*$dArguments';
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      result += '**$dKeywordArguments';
    }

    return result + ')';
  }
}

class Test extends Expression implements Callable {
  Test(this.name,
      {this.expression,
      this.arguments,
      this.keywordArguments,
      this.dArguments,
      this.dKeywordArguments});

  String name;

  @override
  Expression? expression;

  @override
  List<Expression>? arguments;

  @override
  List<Keyword>? keywordArguments;

  @override
  Expression? dArguments;

  @override
  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTest(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    final expression = this.expression;

    if (expression != null) {
      visitor(expression);
    }

    final arguments = this.arguments;

    if (arguments != null) {
      arguments.forEach(visitor);
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null) {
      keywordArguments.forEach(visitor);
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      visitor(dArguments);
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      visitor(dKeywordArguments);
    }
  }

  @override
  String toString() {
    var result = 'Test(\'$name\'';

    if (expression != null) {
      result += ', $expression';
    }

    final arguments = this.arguments;

    if (arguments != null && arguments.isNotEmpty) {
      result += arguments.join(', ');
    }

    final keywordArguments = this.keywordArguments;

    if (keywordArguments != null && keywordArguments.isNotEmpty) {
      result += keywordArguments.join(', ');
    }

    final dArguments = this.dArguments;

    if (dArguments != null) {
      result += '*$dArguments';
    }

    final dKeywordArguments = this.dKeywordArguments;

    if (dKeywordArguments != null) {
      result += '**$dKeywordArguments';
    }

    return result + ')';
  }
}

class Compare extends Expression {
  Compare(this.expression, this.operands);

  Expression expression;

  List<Operand> operands;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(expression);
    operands.forEach(visitor);
  }

  @override
  String toString() {
    return 'Compare($expression, $operands)';
  }
}

class Condition extends Expression {
  Condition(this.test, this.expression1, [this.expression2]);

  Expression test;

  Expression expression1;

  Expression? expression2;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCondition(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(test);
    visitor(expression1);

    final expression2 = this.expression2;

    if (expression2 != null) {
      visitor(expression2);
    }
  }

  @override
  String toString() {
    return expression2 == null
        ? 'Condition($test, $expression1)'
        : 'Condition($test, $expression1, $expression2)';
  }
}

abstract class Literal extends Expression {
  @override
  String toString() {
    return 'Literal()';
  }
}

class Data extends Literal {
  Data([this.data = '']);

  String data;

  String get trimmed {
    return data.trim();
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitData(this, context);
  }

  @override
  String toString() {
    return 'Data(\'${data.replaceAll('\'', '\\\'').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}\')';
  }
}

class Constant<T> extends Literal {
  Constant(this.value);

  T? value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConstant(this, context);
  }

  @override
  String toString() {
    return 'Constant<$T>(${repr(value).replaceAll('\n', r'\n')})';
  }
}

class TupleLiteral extends Literal implements CanAssign {
  TupleLiteral(this.expressions, [AssignContext? context]);

  List<Expression> expressions;

  @override
  bool get canAssign {
    return expressions
        .every((expression) => expression is CanAssign && expression.canAssign);
  }

  @override
  AssignContext get context {
    AssignContext? context;

    for (final expression in expressions) {
      if (expression is CanAssign) {
        if (context == null) {
          context = expression.context;
        } else if (expression.context != context) {
          throw StateError(
              '${expression.runtimeType} context must be $context');
        }
      }
    }

    return context ?? AssignContext.load;
  }

  @override
  set context(AssignContext context) {
    for (final expression in expressions) {
      if (expression is CanAssign) {
        expression.context = context;
      } else {
        // TODO: add error message
        throw TypeError();
      }
    }
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTupleLiteral(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'Tuple(${expressions.join(', ')})';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitListLiteral(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    expressions.forEach(visitor);
  }

  @override
  String toString() {
    return 'List(${expressions.join(', ')})';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.pairs);

  List<Pair> pairs;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDictLiteral(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    pairs.forEach(visitor);
  }

  @override
  String toString() {
    return 'Dict(${pairs.join(', ')})';
  }
}

abstract class Unary extends Expression {
  Unary(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitUnary(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(expression);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $expression)';
  }
}

class Pos extends Unary {
  Pos(Expression expression) : super('+', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPos(this, context);
  }

  @override
  String toString() {
    return 'Pos($expression)';
  }
}

class Neg extends Unary {
  Neg(Expression expression) : super('-', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNeg(this, context);
  }

  @override
  String toString() {
    return 'Neg($expression)';
  }
}

class Not extends Unary {
  Not(Expression expression) : super('not', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNot(this, context);
  }

  @override
  String toString() {
    return 'Not($expression)';
  }
}

abstract class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  String operator;

  Expression left;

  Expression right;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBinary(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(left);
    visitor(right);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $left, $right)';
  }
}

class Pow extends Binary {
  Pow(Expression left, Expression right) : super('**', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPow(this, context);
  }

  @override
  String toString() {
    return 'Pow($left, $right)';
  }
}

class Mul extends Binary {
  Mul(Expression left, Expression right) : super('*', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMul(this, context);
  }

  @override
  String toString() {
    return 'Mul($left, $right)';
  }
}

class Div extends Binary {
  Div(Expression left, Expression right) : super('/', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDiv(this, context);
  }

  @override
  String toString() {
    return 'Div($left, $right)';
  }
}

class FloorDiv extends Binary {
  FloorDiv(Expression left, Expression right) : super('//', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFloorDiv(this, context);
  }

  @override
  String toString() {
    return 'FloorDiv($left, $right)';
  }
}

class Mod extends Binary {
  Mod(Expression left, Expression right) : super('%', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMod(this, context);
  }

  @override
  String toString() {
    return 'Mod($left, $right)';
  }
}

class Add extends Binary {
  Add(Expression left, Expression right) : super('+', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAdd(this, context);
  }

  @override
  String toString() {
    return 'Add($left, $right)';
  }
}

class Sub extends Binary {
  Sub(Expression left, Expression right) : super('-', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSub(this, context);
  }

  @override
  String toString() {
    return 'Sub($left, $right)';
  }
}

class And extends Binary {
  And(Expression left, Expression right) : super('and', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAnd(this, context);
  }

  @override
  String toString() {
    return 'And($left, $right)';
  }
}

class Or extends Binary {
  Or(Expression left, Expression right) : super('or', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOr(this, context);
  }

  @override
  String toString() {
    return 'Or($left, $right)';
  }
}
