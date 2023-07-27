import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/loop.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/namespace.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/tests.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';

abstract base class RenderContext extends Context {
  RenderContext(
    super.environment, {
    Map<String, List<Block>>? blocks,
    super.parent,
    super.data,
  }) : blocks = blocks ?? <String, List<Block>>{};

  final Map<String, List<Block>> blocks;

  @override
  RenderContext derived({
    Map<String, List<Block>>? blocks,
    Map<String, Object?>? data,
  });

  Map<String, Object?> save(Map<String, Object?> map) {
    var save = <String, Object?>{};

    for (var key in map.keys) {
      save[key] = context[key];
      context[key] = map[key];
    }

    return save;
  }

  void restore(Map<String, Object?> map) {
    context.addAll(map);
  }

  void set(String key, Object? value) {
    context[key] = value;
  }

  bool remove(String name) {
    if (context.containsKey(name)) {
      context.remove(name);
      return true;
    }

    return false;
  }

  Object finalize(Object? object) {
    return environment.finalize(this, object);
  }

  void assignTargets(Object? target, Object? current) {
    if (target case String string) {
      set(string, current);
      return;
    }

    if (target case List<String> strings) {
      var values = list(current);

      if (values.length < strings.length) {
        // TODO(renderer): update error
        throw StateError('Not enough values to unpack');
      }

      if (values.length > strings.length) {
        // TODO(renderer): update error
        throw StateError('Too many values to unpack.');
      }

      for (var i = 0; i < strings.length; i++) {
        set(strings[i], values[i]);
      }

      return;
    }

    if (target case NamespaceValue namespaceValue) {
      var value = resolve(namespaceValue.name);

      if (value case Namespace namespace) {
        namespace[target.item] = current;
        return;
      }

      throw TemplateRuntimeError('Non-namespace object');
    }

    // TODO(renderer): update error
    throw TypeError();
  }
}

final class StringSinkRenderContext extends RenderContext {
  StringSinkRenderContext(
    super.environment,
    this.sink, {
    super.blocks,
    super.parent,
    super.data,
  });

  final StringSink sink;

  @override
  StringSinkRenderContext derived({
    StringSink? sink,
    Map<String, List<Block>>? blocks,
    Map<String, Object?>? data,
  }) {
    return StringSinkRenderContext(
      environment,
      sink ?? this.sink,
      blocks: blocks ?? this.blocks,
      parent: context,
      data: data,
    );
  }

  void write(Object? object) {
    sink.write(object);
  }
}

class StringSinkRenderer extends Visitor<StringSinkRenderContext, Object?> {
  const StringSinkRenderer();

  Map<String, Object?> getDataForTargets(Object? targets, Object? current) {
    if (targets case String string) {
      return <String, Object?>{string: current};
    }

    if (targets case List<Object?> targets) {
      var names = targets.cast<String>();
      var values = list(current);

      if (values.length < names.length) {
        // TODO(renderer): update error
        throw StateError(
            'Not enough values to unpack (expected ${names.length}, '
            'got ${values.length})');
      }

      if (values.length > names.length) {
        // TODO(renderer): update error
        throw StateError(
            'Too many values to unpack (expected ${names.length})');
      }

      return <String, Object?>{
        for (var i = 0; i < names.length; i++) names[i]: values[i]
      };
    }

    // TODO(renderer): update error
    throw ArgumentError.value(targets, 'targets', 'must be ListOr<String>');
  }

  MacroFunction getMacroFunction(
    MacroCall node,
    StringSinkRenderContext context,
  ) {
    return (List<Object?> positional, Map<Object?, Object?> named) {
      var buffer = StringBuffer();
      var derived = context.derived(sink: buffer);
      var index = 0;

      var length = node.positional.length;

      for (; index < length; index += 1) {
        var key = node.positional[index].accept(this, context) as String;
        derived.set(key, positional[index]);
      }

      if (node.varargs) {
        derived.set('varargs', positional.sublist(index));
      } else if (index < positional.length) {
        throw TypeError();
      }

      var remaining = named.keys.toSet();

      for (var (argument, defaultValue) in node.named) {
        var key = argument.accept(this, context) as String;

        if (remaining.remove(key)) {
          derived.set(key, named[key]);
        } else {
          derived.set(key, defaultValue.accept(this, context));
        }
      }

      if (node.kwargs) {
        derived.set('kwargs', <Object?, Object?>{
          for (var key in remaining) key: named[key],
        });
      } else if (remaining.isNotEmpty) {
        throw TypeError();
      }

      node.body.accept(this, derived);
      return buffer.toString();
    };
  }

  // Expressions

  @override
  List<Object?> visitArray(Array node, StringSinkRenderContext context) {
    return <Object?>[
      for (var value in node.values) value.accept(this, context)
    ];
  }

  @override
  Object? visitAttribute(Attribute node, StringSinkRenderContext context) {
    var value = node.value.accept(this, context);
    return context.attribute(node.attribute, value);
  }

  @override
  Object? visitCall(Call node, StringSinkRenderContext context) {
    var function = node.value.accept(this, context);
    var (positional, named) = node.calling.accept(this, context) as Parameters;
    return context.call(function, positional, named);
  }

  @override
  Parameters visitCalling(Calling node, StringSinkRenderContext context) {
    var positional = <Object?>[
      for (var argument in node.arguments) argument.accept(this, context)
    ];

    if (node.dArguments case var dArguments?) {
      var values = dArguments.accept(this, context);

      if (values is! Iterable) {
        throw TypeError();
      }

      positional.addAll(values);
    }

    var named = <Symbol, Object?>{
      for (var (:key, :value) in node.keywords)
        Symbol(key): value.accept(this, context)
    };

    if (node.dKeywords case var dKeywords?) {
      var values = dKeywords.accept(this, context);

      if (values is! Map) {
        throw TypeError();
      }

      var castedValues = values.cast<String, Object?>();

      for (var MapEntry(key: key, value: value) in castedValues.entries) {
        named[Symbol(key)] = value;
      }
    }

    return (positional, named);
  }

  @override
  bool visitCompare(Compare node, StringSinkRenderContext context) {
    var left = node.value.accept(this, context);

    for (var (operator, value) in node.operands) {
      var right = value.accept(this, context);

      var result = switch (operator) {
        CompareOperator.equal => isEqual(left, right),
        CompareOperator.notEqual => isNotEqual(left, right),
        CompareOperator.lessThan => isLessThan(left, right),
        CompareOperator.lessThanOrEqual => isLessThanOrEqual(left, right),
        CompareOperator.greaterThan => isGreaterThan(left, right),
        CompareOperator.greaterThanOrEqual => isGreaterThanOrEqual(left, right),
        CompareOperator.contains => isIn(left, right),
        CompareOperator.notContains => !isIn(left, right),
      };

      if (!result) {
        return false;
      }

      left = right;
    }

    return true;
  }

  @override
  Object? visitConcat(Concat node, StringSinkRenderContext context) {
    var buffer = StringBuffer();

    for (var value in node.values) {
      buffer.write(value.accept(this, context));
    }

    return '$buffer';
  }

  @override
  Object? visitCondition(Condition node, StringSinkRenderContext context) {
    if (boolean(node.test.accept(this, context))) {
      return node.trueValue.accept(this, context);
    }

    return node.falseValue?.accept(this, context);
  }

  @override
  Object? visitConstant(Constant node, StringSinkRenderContext context) {
    return node.value;
  }

  @override
  Map<Object?, Object?> visitDict(Dict node, StringSinkRenderContext context) {
    return <Object?, Object?>{
      for (var (:key, :value) in node.pairs)
        key.accept(this, context): value.accept(this, context)
    };
  }

  @override
  Object? visitFilter(Filter node, StringSinkRenderContext context) {
    var (positional, named) = node.calling.accept(this, context) as Parameters;
    return context.filter(node.name, positional, named);
  }

  @override
  Object? visitItem(Item node, StringSinkRenderContext context) {
    var key = node.key.accept(this, context);
    var value = node.value.accept(this, context);
    return context.item(key!, value);
  }

  @override
  Object? visitLogical(Logical node, StringSinkRenderContext context) {
    var left = node.left.accept(this, context);

    return switch (node.operator) {
      LogicalOperator.and =>
        boolean(left) ? node.right.accept(this, context) : left,
      LogicalOperator.or =>
        boolean(left) ? left : node.right.accept(this, context),
    };
  }

  @override
  Object? visitName(Name node, StringSinkRenderContext context) {
    return switch (node.context) {
      AssignContext.load => context.resolve(node.name),
      AssignContext.store || AssignContext.parameter => node.name,
    };
  }

  @override
  NamespaceValue visitNamespaceRef(
    NamespaceRef node,
    StringSinkRenderContext context,
  ) {
    return NamespaceValue(node.name, node.attribute);
  }

  @override
  Object? visitScalar(Scalar node, StringSinkRenderContext context) {
    var left = node.left.accept(this, context);
    var right = node.right.accept(this, context);

    return switch (node.operator) {
      ScalarOperator.power => math.pow(left as num, right as num),
      // ignore: avoid_dynamic_calls
      ScalarOperator.module => (left as dynamic) % right,
      // ignore: avoid_dynamic_calls
      ScalarOperator.floorDivision => (left as dynamic) ~/ right,
      // ignore: avoid_dynamic_calls
      ScalarOperator.division => (left as dynamic) / right,
      // ignore: avoid_dynamic_calls
      ScalarOperator.multiple => (left as dynamic) * right,
      // ignore: avoid_dynamic_calls
      ScalarOperator.minus => (left as dynamic) - right,
      // ignore: avoid_dynamic_calls
      ScalarOperator.plus => (left as dynamic) + right,
    };
  }

  @override
  Object? visitTest(Test node, StringSinkRenderContext context) {
    var (positional, named) = node.calling.accept(this, context) as Parameters;
    return context.test(node.name, positional, named);
  }

  @override
  List<Object?> visitTuple(Tuple node, StringSinkRenderContext context) {
    return <Object?>[
      for (var value in node.values) value.accept(this, context)
    ];
  }

  @override
  Object? visitUnary(Unary node, StringSinkRenderContext context) {
    var value = node.value.accept(this, context);

    return switch (node.operator) {
      UnaryOperator.plus => value,
      // ignore: avoid_dynamic_calls
      UnaryOperator.minus => -(value as dynamic),
      UnaryOperator.not => !boolean(value),
    };
  }

  // Statements

  @override
  void visitAssign(Assign node, StringSinkRenderContext context) {
    var target = node.target.accept(this, context);
    var values = node.value.accept(this, context);
    context.assignTargets(target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, StringSinkRenderContext context) {
    var target = node.target.accept(this, context);
    var buffer = StringBuffer();
    var derived = context.derived(sink: buffer);
    node.body.accept(this, derived);

    Object? value = '$buffer';

    var filters = node.filters;

    if (filters.isEmpty) {
      if (context.autoEscape) {
        value = Markup.escaped(value);
      }

      context.assignTargets(target, value);
    } else {
      // TODO(renderer): replace with Filter { BlockExpression ( AssignBlock ) }
      for (var Filter(name: name, calling: calling) in filters) {
        var (positional, named) = calling.accept(this, context) as Parameters;
        positional = [value, ...positional];
        value = context.filter(name, positional, named);
      }

      if (context.autoEscape) {
        value = Markup.escaped(value);
      }

      context.assignTargets(target, value);
    }
  }

  @override
  void visitAutoEscape(AutoEscape node, StringSinkRenderContext context) {
    var current = context.autoEscape;
    context.autoEscape = boolean(node.value.accept(this, context));
    node.body.accept(this, context);
    context.autoEscape = current;
  }

  @override
  void visitBlock(Block node, StringSinkRenderContext context) {
    var blocks = context.blocks[node.name];

    if (blocks == null || blocks.isEmpty) {
      node.body.accept(this, context);
    } else {
      if (node.required) {
        if (blocks.length == 1) {
          throw TemplateRuntimeError("Required block '${node.name}' not found");
        }
      }

      var first = blocks[0];
      var index = 0;

      // TODO(renderer): move to context
      String parent() {
        if (index < blocks.length - 1) {
          var parentBlock = blocks[index += 1];
          parentBlock.body.accept(this, context);
          return '';
        }

        // TODO(renderer): add error message
        throw TemplateRuntimeError();
      }

      context.set('super', parent);
      first.body.accept(this, context);
      context.remove('super');
    }
  }

  @override
  void visitCallBlock(CallBlock node, StringSinkRenderContext context) {
    var function = node.call.value.accept(this, context) as MacroFunction;
    var (arguments, _) = node.call.calling.accept(this, context) as Parameters;
    var [positional as List, named as Map] = arguments;
    named['caller'] = getMacroFunction(node, context);
    context.write(context.call(function, <Object?>[positional, named]));
  }

  @override
  void visitData(Data node, StringSinkRenderContext context) {
    context.write(node.data);
  }

  @override
  void visitDo(Do node, StringSinkRenderContext context) {
    node.value.accept(this, context);
  }

  @override
  void visitExtends(Extends node, StringSinkRenderContext context) {
    var template = context.environment.getTemplate(node.path);
    template.body.accept(this, context);
  }

  @override
  void visitFilterBlock(FilterBlock node, StringSinkRenderContext context) {
    var buffer = StringBuffer();
    var derived = context.derived(sink: buffer);
    node.body.accept(this, derived);

    Object? value = '$buffer';

    for (var Filter(name: name, calling: calling) in node.filters) {
      var (positional, named) = calling.accept(this, context) as Parameters;
      positional = <Object?>[value, ...positional];
      value = context.filter(name, positional, named);
    }

    context.write(value);
  }

  @override
  void visitFor(For node, StringSinkRenderContext context) {
    var targets = node.target.accept(this, context);
    var iterable = node.iterable.accept(this, context);

    if (iterable == null) {
      throw ArgumentError.notNull('iterable');
    }

    String render(Object? iterable, [int depth = 0]) {
      List<Object?> values;

      if (iterable is Map) {
        values = iterable.entries.toList();
      } else {
        values = list(iterable);
      }

      if (values.isEmpty) {
        if (node.orElse case var orElse?) {
          orElse.accept(this, context);
        }

        return '';
      }

      if (node.test != null) {
        var test = node.test!;
        var filtered = <Object?>[];

        for (var value in values) {
          var data = getDataForTargets(targets, value);
          data = context.save(data);

          if (boolean(test.accept(this, context))) {
            filtered.add(value);
          }

          context.restore(data);
        }

        values = filtered;
      }

      var loop = LoopContext(values, depth, render);
      var parent = context.get('loop');
      context.set('loop', loop);

      for (var value in loop) {
        var data = getDataForTargets(targets, value);
        var forContext = context.derived(data: data);
        node.body.accept(this, forContext);
      }

      context.set('loop', parent);
      return '';
    }

    render(iterable);
  }

  @override
  void visitIf(If node, StringSinkRenderContext context) {
    if (boolean(node.test.accept(this, context))) {
      node.body.accept(this, context);
    } else if (node.orElse case var orElse?) {
      orElse.accept(this, context);
    }
  }

  @override
  void visitInclude(Include node, StringSinkRenderContext context) {
    var template = context.environment.getTemplate(node.template);

    if (!node.withContext) {
      context = StringSinkRenderContext(context.environment, context.sink);
    }

    template.body.accept(this, context);
  }

  @override
  void visitInterpolation(Interpolation node, StringSinkRenderContext context) {
    var resolved = node.value.accept(this, context);
    var finalized = context.finalize(resolved);
    var escaped = context.escape(finalized);
    context.write(escaped);
  }

  @override
  void visitMacro(Macro node, StringSinkRenderContext context) {
    // TODO(renderer): handle varargs, kwargs
    var function = getMacroFunction(node, context);
    context.set(node.name, function);
  }

  @override
  void visitOutput(Output node, StringSinkRenderContext context) {
    for (var node in node.nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitTemplateNode(TemplateNode node, StringSinkRenderContext context) {
    var self = Namespace();

    for (var block in node.blocks) {
      var blocks = context.blocks[block.name] ??= <Block>[];
      blocks.add(block);

      String render() {
        block.accept(this, context);
        return '';
      }

      self[block.name] = render;
    }

    context.set('self', self);
    node.body.accept(this, context);
  }

  @override
  void visitWith(With node, StringSinkRenderContext context) {
    var targets = <Object?>[
      for (var target in node.targets) target.accept(this, context)
    ];

    var values = <Object?>[
      for (var value in node.values) value.accept(this, context)
    ];

    var data = context.save(getDataForTargets(targets, values));
    node.body.accept(this, context);
    context.restore(data);
  }
}
