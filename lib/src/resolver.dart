import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'environment.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

class ExpressionResolver<C extends Context> extends Visitor<C, Object?> {
  @literal
  const ExpressionResolver();

  // TODO: update calling
  @internal
  T Function(T Function(List<Object?>, Map<Symbol, Object?>)) callable<T>(
      Callable callable, C context) {
    final positional = <Object?>[];
    final arguments = callable.arguments;

    if (arguments != null) {
      for (final argument in arguments) {
        positional.add(argument.accept(this, context));
      }
    }

    final named = <Symbol, Object?>{};
    final keywordArguments = callable.keywordArguments;

    if (keywordArguments != null) {
      for (final argument in keywordArguments) {
        named[symbol(argument.key)] = argument.value.accept(this, context);
      }
    }

    final dArguments = callable.dArguments;

    if (dArguments != null) {
      positional.addAll(dArguments.accept(this, context) as Iterable<Object?>);
    }

    final dKeywordArguments = callable.dKeywordArguments;

    if (dKeywordArguments != null) {
      named.addAll((dKeywordArguments.accept(this, context)
              as Map<Object?, Object?>)
          .cast<String, Object?>()
          .map<Symbol, Object?>(
              (key, value) => MapEntry<Symbol, Object?>(symbol(key), value)));
    }

    return (T Function(List<Object?> positional, Map<Symbol, Object?> named)
            callback) =>
        callback(positional, named);
  }

  // TODO: update filter calling
  @internal
  Object? callFilter(C context, Filter filter, [Object? value]) {
    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context.environment.callFilter(filter.name, value,
          positional: positional, named: named, context: context);
    }

    return callable<Object?>(filter, context)(callback);
  }

  // TODO: update test calling
  @internal
  bool callTest(C context, Test test, [Object? value]) {
    bool callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context.environment
          .callTest(test.name, value, positional: positional, named: named);
    }

    return callable<bool>(test, context)(callback);
  }

  @override
  void visitAll(List<Node> nodes, C context) {
    throw UnimplementedError();
  }

  @override
  void visitAssign(Assign node, C context) {
    throw UnimplementedError();
  }

  @override
  void visitAssignBlock(AssignBlock node, C context) {
    throw UnimplementedError();
  }

  @override
  Object? visitAttribute(Attribute node, C context) {
    return context.environment
        .getAttribute(node.expression.accept(this, context)!, node.attribute);
  }

  @override
  Object? visitBinary(Binary node, C context) {
    final dynamic left = node.left.accept(this, context);
    final dynamic right = node.right.accept(this, context);

    try {
      switch (node.operator) {
        case '**':
          return math.pow(left as num, right as num);
        case '%':
          return left % right;
        case '//':
          return left ~/ right;
        case '/':
          return left / right;
        case '*':
          return left * right;
        case '-':
          return left - right;
        case '+':
          return left + right;
        case 'or':
          return boolean(left) ? left : right;
        case 'and':
          return boolean(left) ? right : left;
      }
    } on TypeError {
      if (left is int && right is String) {
        return right * left;
      }

      rethrow;
    }
  }

  @override
  void visitBlock(Block node, C context) {
    throw UnimplementedError();
  }

  @override
  Object? visitCall(Call node, C context) {
    final dynamic function = node.expression!.accept(this, context)!;

    Object? callback(List<Object?> positional, Map<Symbol, Object?> named) {
      return context(function, positional, named);
    }

    return callable<Object?>(node, context)(callback);
  }

  @override
  Object? visitCompare(Compare node, C context) {
    var left = node.expression.accept(this, context);
    var result = true;

    for (final operand in node.operands) {
      final right = operand.expression.accept(this, context);

      switch (operand.operator) {
        case 'eq':
          result = result && tests.isEqual(left, right);
          break;
        case 'ne':
          result = result && tests.isNotEqual(left, right);
          break;
        case 'lt':
          result = result && tests.isLessThan(left, right);
          break;
        case 'le':
          result = result && tests.isLessThanOrEqual(left, right);
          break;
        case 'gt':
          result = result && tests.isGreaterThan(left, right);
          break;
        case 'ge':
          result = result && tests.isGreaterThanOrEqual(left, right);
          break;
        case 'in':
          result = result && tests.isIn(left, right);
          break;
        case 'notin':
          result = result && !tests.isIn(left, right);
          break;
      }

      if (!result) {
        return false;
      }

      left = right;
    }

    return result;
  }

  @override
  String visitConcat(Concat node, C context) {
    final buffer = StringBuffer();

    for (final expression in node.expressions) {
      buffer.write(expression.accept(this, context));
    }

    return buffer.toString();
  }

  @override
  Object? visitCondition(Condition node, C context) {
    if (boolean(node.test.accept(this, context))) {
      return node.expression1.accept(this, context);
    }

    final expression = node.expression2;

    if (expression != null) {
      return expression.accept(this, context);
    }

    return context.environment.undefined();
  }

  @override
  Object? visitConstant(Constant<Object?> node, C context) {
    return node.value;
  }

  @override
  void visitContextModifier(ScopedContextModifier node, C context) {
    throw UnimplementedError();
  }

  @override
  String visitData(Data node, C context) {
    return node.data;
  }

  @override
  Map<Object?, Object?> visitDictLiteral(DictLiteral node, C context) {
    final result = <Object?, Object?>{};

    for (final pair in node.pairs) {
      result[pair.key.accept(this, context)] = pair.value.accept(this, context);
    }

    return result;
  }

  @override
  void visitDo(Do node, C context) {
    throw UnimplementedError();
  }

  @override
  Object? visitExtends(Extends node, C context) {
    throw UnimplementedError();
  }

  @override
  Object? visitFilter(Filter node, C context) {
    final expression = node.expression;
    Object? value;

    if (expression != null) {
      value = expression.accept(this, context);
    }

    return callFilter(context, node, value);
  }

  @override
  void visitFilterBlock(FilterBlock node, C context) {
    throw UnimplementedError();
  }

  @override
  void visitFor(For node, C context) {
    throw UnimplementedError();
  }

  @override
  void visitIf(If node, C context) {
    throw UnimplementedError();
  }

  @override
  void visitInclude(Include node, C context) {
    throw UnimplementedError();
  }

  @override
  Object? visitItem(Item node, C context) {
    return context.environment.getItem(
        node.expression.accept(this, context)!, node.key.accept(this, context));
  }

  @override
  MapEntry<Symbol, Object?> visitKeyword(Keyword node, C context) {
    return MapEntry<Symbol, Object?>(
        Symbol(node.key), node.value.accept(this, context));
  }

  @override
  List<Object?> visitListLiteral(ListLiteral node, C context) {
    final result = <Object?>[];

    for (final item in node.expressions) {
      result.add(item.accept(this, context));
    }

    return result;
  }

  @override
  Object? visitName(Name node, C context) {
    switch (node.context) {
      case AssignContext.load:
        return context.resolve(node.name);
      case AssignContext.store:
      case AssignContext.parameter:
        return node.name;
      default:
        // TODO: add error message
        throw UnimplementedError();
    }
  }

  @override
  Object? visitNameSpaceReference(NameSpaceReference node, C context) {
    return NameSpaceValue(node.name, node.attribute);
  }

  @override
  Object? visitOperand(Operand node, C context) {
    return <Object?>[node.operator, node.expression.accept(this, context)];
  }

  @override
  void visitOutput(Output node, C context) {
    throw UnimplementedError();
  }

  @override
  MapEntry<Object?, Object?> visitPair(Pair node, C context) {
    return MapEntry<Object?, Object?>(
        node.key.accept(this, context), node.value.accept(this, context));
  }

  @override
  void visitScope(Scope node, C context) {
    throw UnimplementedError();
  }

  @override
  void visitScopedContextModifier(ScopedContextModifier node, C context) {
    throw UnimplementedError();
  }

  @override
  Indices visitSlice(Slice node, C context) {
    final sliceStart = node.start?.accept(this, context) as int?;
    final sliceStop = node.stop?.accept(this, context) as int?;
    final sliceStep = node.step?.accept(this, context) as int?;
    return (int stopOrStart, [int? stop, int? step]) {
      if (sliceStep == null) {
        step = 1;
      } else if (sliceStep == 0) {
        throw StateError('slice step cannot be zero');
      } else {
        step = sliceStep;
      }

      int start;

      if (sliceStart == null) {
        start = step > 0 ? 0 : stopOrStart - 1;
      } else {
        start = sliceStart < 0 ? sliceStart + stopOrStart : sliceStart;
      }

      if (sliceStop == null) {
        stop = step > 0 ? stopOrStart : -1;
      } else {
        stop = sliceStop < 0 ? sliceStop + stopOrStart : sliceStop;
      }

      return range(start, stop, step);
    };
  }

  @override
  void visitTemplate(Template node, C context) {
    throw UnimplementedError();
  }

  @override
  bool visitTest(Test node, C context) {
    Object? value;

    if (node.expression != null) {
      value = node.expression!.accept(this, context);
    }

    return callTest(context, node, value);
  }

  @override
  List<Object?> visitTupleLiteral(TupleLiteral node, C context) {
    switch (node.context) {
      case AssignContext.load:
        final result = <Object?>[];

        for (final item in node.expressions) {
          result.add(item.accept(this, context));
        }

        return result;
      case AssignContext.store:
        final result = <String>[];

        for (final item in node.expressions.cast<Name>()) {
          result.add(item.name);
        }

        return result;
      default:
        throw UnimplementedError();
    }
  }

  @override
  Object? visitUnary(Unary node, C context) {
    final dynamic value = node.expression.accept(this, context);

    switch (node.operator) {
      case '+':
        // how i should implement this?
        return value;
      case '-':
        return -value;
      case 'not':
        return !boolean(value);
    }
  }

  @override
  void visitWith(With node, C context) {
    throw UnimplementedError();
  }

  @internal
  static Symbol symbol(String keyword) {
    switch (keyword) {
      case 'default':
        return #d;
      default:
        return Symbol(keyword);
    }
  }
}
