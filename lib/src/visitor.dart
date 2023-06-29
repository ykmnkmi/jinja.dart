import 'package:jinja/src/environment.dart';
import 'package:jinja/src/nodes.dart';

abstract class Visitor<C, R> {
  const Visitor();

  // Expressions

  R visitArray(Array node, C context);

  R visitAttribute(Attribute node, C context);

  R visitCall(Call node, C context);

  R visitCalling(Calling node, C context);

  R visitCompare(Compare node, C context);

  R visitConcat(Concat node, C context);

  R visitCondition(Condition node, C context);

  R visitConstant(Constant node, C context);

  R visitDict(Dict node, C context);

  R visitFilter(Filter node, C context);

  R visitItem(Item node, C context);

  R visitLogical(Logical node, C context);

  R visitName(Name node, C context);

  R visitNamespaceRef(NamespaceRef node, C context);

  R visitScalar(Scalar node, C context);

  R visitTest(Test node, C context);

  R visitTuple(Tuple node, C context);

  R visitUnary(Unary node, C context);

  // Statements

  R visitAssign(Assign node, C context);

  R visitAssignBlock(AssignBlock node, C context);

  R visitAutoEscape(AutoEscape node, C context);

  R visitBlock(Block node, C context);

  R visitCallBlock(CallBlock node, C context);

  R visitData(Data node, C context);

  R visitDo(Do node, C context);

  R visitExtends(Extends node, C context);

  R visitFilterBlock(FilterBlock node, C context);

  R visitFor(For node, C context);

  R visitIf(If node, C context);

  R visitInclude(Include node, C context);

  R visitInterpolation(Interpolation node, C context);

  R visitMacro(Macro node, C context);

  R visitOutput(Output node, C context);

  R visitTemplateNode(TemplateNode node, C context);

  R visitWith(With node, C context);
}

class ThrowingVisitor<C, R> implements Visitor<C, R> {
  const ThrowingVisitor();

  // Expressions

  @override
  R visitArray(Array node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitAttribute(Attribute node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitAutoEscape(AutoEscape node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitCall(Call node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitCalling(Calling node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitCompare(Compare node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitConcat(Concat node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitCondition(Condition node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitConstant(Constant node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitDict(Dict node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitFilter(Filter node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitItem(Item node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitLogical(Logical node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitName(Name node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitNamespaceRef(NamespaceRef node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitScalar(Scalar node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitTest(Test node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitTuple(Tuple node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitUnary(Unary node, C context) {
    throw UnimplementedError('$node');
  }

  // Statements

  @override
  R visitAssign(Assign node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitAssignBlock(AssignBlock node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitBlock(Block node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitCallBlock(CallBlock node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitData(Data node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitDo(Do node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitExtends(Extends node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitFilterBlock(FilterBlock node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitFor(For node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitIf(If node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitInclude(Include node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitInterpolation(Interpolation node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitMacro(Macro node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitOutput(Output node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitTemplateNode(TemplateNode node, C context) {
    throw UnimplementedError('$node');
  }

  @override
  R visitWith(With node, C context) {
    throw UnimplementedError('$node');
  }
}

class Printer extends ThrowingVisitor<StringBuffer, void> {
  Printer(Environment environment)
      : variableStart = environment.variableStart,
        variableEnd = environment.variableEnd,
        blockStart = environment.blockStart,
        blockEnd = environment.blockEnd;

  final String variableStart;

  final String variableEnd;

  final String blockStart;

  final String blockEnd;

  String visit(Node body) {
    var buffer = StringBuffer();
    body.accept(this, buffer);
    return '$buffer';
  }

  void writeAll(
    StringBuffer context,
    List<Node> nodes, [
    String delimeter = ', ',
  ]) {
    nodes.first.accept(this, context);

    for (var node in nodes.skip(1)) {
      context.write(delimeter);
      node.accept(this, context);
    }
  }

  // Expressions

  @override
  void visitArray(Array node, StringBuffer context) {
    if (node.values.isEmpty) {
      context.write('[]');
    } else {
      context.write('[');
      writeAll(context, node.values);
      context.write(']');
    }
  }

  @override
  void visitAttribute(Attribute node, StringBuffer context) {
    node.value.accept(this, context);
    context.write('.${node.attribute}');
  }

  @override
  void visitCall(Call node, StringBuffer context) {
    node.value.accept(this, context);
    node.calling.accept(this, context);
  }

  @override
  void visitCalling(Calling node, StringBuffer context) {
    context.write('(');

    var comma = '';

    if (node.arguments.isNotEmpty) {
      writeAll(context, node.arguments);
      comma = ', ';
    }

    if (node.keywords.isNotEmpty) {
      context.write(comma);

      var (:key, :value) = node.keywords.first;
      context.write('$key=');
      value.accept(this, context);

      for (var (:key, :value) in node.keywords.skip(1)) {
        context.write(', $key=');
        value.accept(this, context);
      }
    }

    if (node.dArguments case var dArguments?) {
      context.write('$comma*');
      dArguments.accept(this, context);
    }

    if (node.dKeywords case var dKeywords?) {
      context.write('$comma**');
      dKeywords.accept(this, context);
    }

    context.write(')');
  }

  @override
  void visitCompare(Compare node, StringBuffer context) {
    node.value.accept(this, context);

    for (var (operator, value) in node.operands) {
      context.write(' ${operator.symbol} ');
      value.accept(this, context);
    }
  }

  @override
  void visitConcat(Concat node, StringBuffer context) {
    writeAll(context, node.values, ' ~ ');
  }

  @override
  void visitConstant(Constant node, StringBuffer context) {
    if (node.value case String value) {
      context.write('"${value.replaceAll('"', r'\"')}"');
    } else {
      context.write(node.value);
    }
  }

  @override
  void visitDict(Dict node, StringBuffer context) {
    if (node.pairs.isEmpty) {
      context.write('{}');
    } else {
      context.write('{');

      for (var (:key, :value) in node.pairs) {
        key.accept(this, context);
        context.write(': ');
        value.accept(this, context);
      }

      context.write('}');
    }
  }

  @override
  void visitFilter(Filter node, StringBuffer context) {
    node.calling.arguments.first.accept(this, context);
    context.write(' | ${node.name}');
    node.calling
        .copyWith(arguments: node.calling.arguments.sublist(1))
        .accept(this, context);
  }

  @override
  void visitItem(Item node, StringBuffer context) {
    node.value.accept(this, context);
    context.write('[');
    node.key.accept(this, context);
    context.write(']');
  }

  @override
  void visitName(Name node, StringBuffer context) {
    context.write(node.name);
  }

  @override
  void visitNamespaceRef(NamespaceRef node, StringBuffer context) {
    context.write('${node.name}.${node.attribute}');
  }

  // Statements

  @override
  void visitAssign(Assign node, StringBuffer context) {
    context.write('$variableStart set ');
    node.target.accept(this, context);
    context.write(' = ');
    node.value.accept(this, context);
    context.write(' $blockEnd');
  }

  @override
  void visitAssignBlock(AssignBlock node, StringBuffer context) {
    context.write('$variableStart set ');
    node.target.accept(this, context);

    for (var filter in node.filters) {
      context.write(' | ${filter.name}');
      filter.calling.accept(this, context);
    }

    context.write(' $blockEnd');
    node.body.accept(this, context);
    context.write('$blockStart endset $blockEnd');
  }

  @override
  void visitCallBlock(CallBlock node, StringBuffer context) {
    context.write('$blockStart call(');

    if (node.arguments.isNotEmpty) {
      var (argument, default_) = node.arguments.first;

      argument.accept(this, context);

      if (default_ != null) {
        context.write('=');
        default_.accept(this, context);
      }

      for (var (argument, default_) in node.arguments.skip(1)) {
        context.write(', ');
        argument.accept(this, context);

        if (default_ != null) {
          context.write('=');
          default_.accept(this, context);
        }
      }
    }

    context.write(') ');
    node.call.accept(this, context);
    context.write(' $blockEnd');
    node.body.accept(this, context);
    context.write('$blockStart endmacro $blockEnd');
  }

  @override
  void visitData(Data node, StringBuffer context) {
    context.write(node.data);
  }

  @override
  void visitExtends(Extends node, StringBuffer context) {
    context.write('$blockStart extends "${node.path}" $blockEnd');
  }

  @override
  void visitFor(For node, StringBuffer context) {
    context.write('$blockStart for ');
    node.target.accept(this, context);
    context.write(' in ');
    node.iterable.accept(this, context);

    if (node.test case var test?) {
      context.write(' ');
      test.accept(this, context);
    }

    if (node.recursive) {
      context.write(' recursive');
    }

    context.write(' $blockEnd');
    node.body.accept(this, context);

    if (node.orElse case var orElse?) {
      context.write('$blockStart else $blockEnd');
      orElse.accept(this, context);
    }

    context.write('$blockStart endfor $blockEnd');
  }

  @override
  void visitInterpolation(Interpolation node, StringBuffer context) {
    context.write('$variableStart ');
    node.value.accept(this, context);
    context.write(' $variableEnd');
  }

  @override
  void visitLogical(Logical node, StringBuffer context) {
    node.left.accept(this, context);
    context.write(' ${node.operator.name} ');
    node.right.accept(this, context);
  }

  @override
  void visitMacro(Macro node, StringBuffer context) {
    context.write('$blockStart macro ${node.name}(');

    if (node.arguments.isNotEmpty) {
      var (argument, default_) = node.arguments.first;

      argument.accept(this, context);

      if (default_ != null) {
        context.write('=');
        default_.accept(this, context);
      }

      for (var (argument, default_) in node.arguments.skip(1)) {
        context.write(', ');
        argument.accept(this, context);

        if (default_ != null) {
          context.write('=');
          default_.accept(this, context);
        }
      }
    }

    context.write(') $variableEnd');
    node.body.accept(this, context);
    context.write('$blockStart endmacro $blockEnd');
  }

  @override
  void visitOutput(Output node, StringBuffer context) {
    for (var node in node.nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitTemplateNode(TemplateNode node, StringBuffer context) {
    node.body.accept(this, context);
  }
}
