import 'dart:collection';
import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/loop.dart';
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
  }) : blocks = blocks ?? HashMap<String, List<Block>>();

  final Map<String, List<Block>> blocks;

  @override
  RenderContext derived({
    Map<String, List<Block>>? blocks,
    Map<String, Object?>? data,
  });

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

  Object? finalize(Object? object) {
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
        throw StateError('Not enough values to unpack.');
      }

      if (values.length > strings.length) {
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

    throw TypeError();
  }
}

base class StringSinkRenderContext extends RenderContext {
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
    bool withContext = true,
  }) {
    Map<String, Object?> parent;

    if (withContext) {
      parent = HashMap<String, Object?>.of(this.parent)..addAll(context);
    } else {
      parent = this.parent;
    }

    return StringSinkRenderContext(
      environment,
      sink ?? this.sink,
      blocks: blocks ?? this.blocks,
      parent: parent,
      data: data,
    );
  }

  void write(Object? value) {
    sink.write(value);
  }
}

base class StringSinkRenderer
    extends Visitor<StringSinkRenderContext, Object?> {
  const StringSinkRenderer();

  Map<String, Object?> getDataForTargets(Object? targets, Object? current) {
    if (targets case String string) {
      return <String, Object?>{string: current};
    }

    if (targets case List<Object?> targets) {
      var names = targets.cast<String>();
      var values = list(current);

      if (values.length < names.length) {
        throw StateError(
            'Not enough values to unpack (expected ${names.length}, '
            'got ${values.length}).');
      }

      if (values.length > names.length) {
        throw StateError(
            'Too many values to unpack (expected ${names.length}).');
      }

      return <String, Object?>{
        for (var i = 0; i < names.length; i++) names[i]: values[i]
      };
    }

    // TODO(renderer): add error message
    throw ArgumentError.value(targets, 'targets');
  }

  MacroFunction getMacroFunction(
    MacroCall node,
    StringSinkRenderContext context,
  ) {
    String macro(List<Object?> positional, Map<Object?, Object?> named) {
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
      return '$buffer';
    }

    return macro;
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

    var named = <Symbol, Object?>{
      for (var (:key, :value) in node.keywords)
        Symbol(key): value.accept(this, context)
    };

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
    return context.item(key, value);
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
      _ => node.name,
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
      context.assignTargets(target, value);
    } else {
      // TODO(renderer): replace with Filter { BlockExpression ( AssignBlock ) }
      for (var Filter(name: name, calling: calling) in filters) {
        var (positional, named) = calling.accept(this, context) as Parameters;
        positional = [value, ...positional];
        value = context.filter(name, positional, named);
      }

      context.assignTargets(target, value);
    }
  }

  @override
  void visitBlock(Block node, StringSinkRenderContext context) {
    var blocks = context.blocks[node.name];

    if (blocks == null || blocks.isEmpty) {
      node.body.accept(this, context);
    } else {
      if (node.required) {
        if (blocks.length == 1) {
          throw TemplateRuntimeError(
              "Required block '${node.name}' not found.");
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
    var templateOrParth = node.template.accept(this, context);

    var template = switch (templateOrParth) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

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
          var newContext = context.derived(data: data);

          if (boolean(test.accept(this, newContext))) {
            filtered.add(value);
          }
        }

        values = filtered;
      }

      var loop = LoopContext(values, depth, render);
      var parent = context.resolve('loop');
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
  void visitFromImport(FromImport node, StringSinkRenderContext context) {
    var templateOrParth = node.template.accept(this, context);

    var template = switch (templateOrParth) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    for (var (name, alias) in node.names) {
      String macro(List<Object?> positional, Map<Object?, Object?> named) {
        Macro targetMacro;

        if (template.body case Macro macro) {
          if (macro.name != name) {
            throw TemplateRuntimeError(
                "The '${template.path}' does not export the requested name.");
          }

          targetMacro = macro;
        } else if (template.body case TemplateNode body) {
          found:
          {
            for (var macro in body.macros) {
              if (macro.name == name) {
                targetMacro = macro;
                break found;
              }
            }

            throw TemplateRuntimeError(
                "The '${template.path}' does not export the requested name.");
          }
        } else {
          throw TemplateRuntimeError('Non-macro object.');
        }

        if (node.withContext) {
          var function = getMacroFunction(targetMacro, context);
          return function(positional, named.cast<Symbol, Object?>());
        } else {
          var newContext = context.derived(withContext: false);
          var function = getMacroFunction(targetMacro, newContext);
          return function(positional, named.cast<Symbol, Object?>());
        }
      }

      context.set(alias ?? name, macro);
    }
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
  void visitImport(Import node, StringSinkRenderContext context) {
    var templateOrParth = node.template.accept(this, context);

    var template = switch (templateOrParth) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    List<Macro> macros;

    if (template.body case Macro macro) {
      macros = <Macro>[macro];
    } else if (template.body case TemplateNode body) {
      macros = body.macros;
    } else {
      // TODO(renderer): update error message
      throw TemplateRuntimeError('Non-macro object.');
    }

    var namespace = Namespace();

    for (var macro in macros) {
      if (node.withContext) {
        namespace[macro.name] = getMacroFunction(macro, context);
      } else {
        var newContext = context.derived(withContext: false);
        namespace[macro.name] = getMacroFunction(macro, newContext);
      }
    }

    context.set(node.target, namespace);
  }

  @override
  void visitInclude(Include node, StringSinkRenderContext context) {
    var templateOrParth = node.template.accept(this, context);

    var template = switch (templateOrParth) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    if (!node.withContext) {
      context = context.derived(withContext: false);
    }

    template.body.accept(this, context);
  }

  @override
  void visitInterpolation(Interpolation node, StringSinkRenderContext context) {
    var value = node.value.accept(this, context);
    var finalized = context.finalize(value);
    context.write(finalized);
  }

  @override
  void visitMacro(Macro node, StringSinkRenderContext context) {
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

    var data = getDataForTargets(targets, values);
    var newContext = context.derived(data: data);
    node.body.accept(this, newContext);
  }
}
