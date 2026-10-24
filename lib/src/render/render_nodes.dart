// TODO(renderer): convert to visitor.
library;

import 'dart:math' as math;

import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/render/render_context.dart';
import 'package:jinja/src/runtime.dart';
import 'package:jinja/src/tests.dart';
import 'package:jinja/src/utils.dart';

String _symbolToName(Symbol symbol) {
  var str = symbol.toString();
  return str.substring(8, str.length - 2);
}

// Interfaces

abstract base class RenderNode {
  const new();

  void render(RenderContext context);
}

final class REmpty extends RenderNode {
  const new();

  @override
  void render(RenderContext context) {}
}

final class RData extends RenderNode {
  const new(this.data);

  final String data;

  @override
  void render(RenderContext context) {
    context.write(data);
  }
}

abstract base class RFunction extends RenderNode {
  const new();

  void call(RenderContext context);

  @override
  void render(RenderContext context) {
    call(context);
  }
}

abstract base class RExpression extends RenderNode {
  const new();

  Object? eval(RenderContext context);

  @override
  void render(RenderContext context) {
    context.write(context.finalize(eval(context)));
  }
}

abstract base class RStatement extends RenderNode {
  const new();
}

// Core

final class ROutput extends RenderNode {
  const new(this.nodes, {this.checkParent = false});

  final List<RenderNode> nodes;

  final bool checkParent;

  @override
  void render(RenderContext context) {
    if (checkParent && context.parentTemplate != null) {
      return;
    }

    for (var node in nodes) {
      node.render(context);
    }
  }
}

final class RBlock extends RFunction {
  const new({
    required this.name,
    required this.scoped,
    required this.required,
    required this.hasSuper,
    required this.hasSelf,
    required this.nodes,
  });

  final String name;

  final bool scoped;

  final bool required;

  final bool hasSuper;

  final bool hasSelf;

  final List<RenderNode> nodes;

  @override
  void call(RenderContext context) {
    register(context);
  }

  void register(RenderContext context) {
    context.self[name] ??= () {
      var blocks = context.blocks[name];

      if (blocks == null || blocks.isEmpty) {
        throw UndefinedError("Block '$name' is not defined.");
      }

      var buffer = StringBuffer();
      blocks[0](context.derived(sink: buffer));
      return buffer.toString();
    };

    var blocks = context.blocks[name] ??= <ContextCallback>[];

    if (required) {
      Never callback(Context context) {
        throw TemplateRuntimeError("Required block '$name' not found.");
      }

      blocks.add(callback);
    } else {
      var parentIndex = blocks.length + 1;

      void callback(Context context) {
        var renderContext = (context as RenderContext).derived();

        if (hasSelf && !renderContext.has('self')) {
          renderContext.set('self', renderContext.self);
        }

        if (hasSuper) {
          String parent() {
            var chain = renderContext.blocks[name]!;

            if (parentIndex >= chain.length) {
              throw TemplateRuntimeError("Super block '$name' not found.");
            }

            var buffer = StringBuffer();
            chain[parentIndex](renderContext.derived(sink: buffer));
            return buffer.toString();
          }

          renderContext.set('super', parent);
        }

        for (var node in nodes) {
          node.render(renderContext);
        }
      }

      blocks.add(callback);
    }
  }
}

final class RTemplateNode extends RenderNode {
  const new(
    this.nodes, {
    this.blocks = const <RBlock>[],
    this.haveExtends = false,
    this.haveSelf = false,
  });

  final List<RenderNode> nodes;

  final List<RBlock> blocks;

  final bool haveExtends;

  final bool haveSelf;

  void registerBlocks(RenderContext context) {
    for (var block in blocks) {
      block.register(context);
    }
  }

  @override
  void render(RenderContext context) {
    registerBlocks(context);

    if (haveSelf && !context.has('self')) {
      context.set('self', context.self);
    }

    for (var node in nodes) {
      node.render(context);
    }

    if (haveExtends) {
      if (context.parentTemplate case var parentTemplate?) {
        context.parentTemplate = null;
        parentTemplate.renderNode.render(context);
      }
    }
  }
}

// Expressions

final class RBlockExpression extends RExpression {
  const new(this.nodes);

  final List<RenderNode> nodes;

  @override
  Object? eval(RenderContext context) {
    var buffer = StringBuffer();
    var derived = context.derived(sink: buffer);

    for (var node in nodes) {
      node.render(derived);
    }

    return buffer.toString();
  }
}

final class RCall extends RExpression {
  const new(this.function, this.positional, this.named);

  final RExpression function;

  final List<RExpression> positional;

  final Map<Symbol, RExpression> named;

  @override
  Object? eval(RenderContext context) {
    var function = this.function.eval(context);

    var positional = <Object?>[
      for (var argument in this.positional) argument.eval(context),
    ];

    var named = <Symbol, Object?>{
      for (var entry in this.named.entries)
        entry.key: entry.value.eval(context),
    };

    return context.call(function, positional, named);
  }
}

final class RCompareOperand {
  const new(this.operator, this.value);

  final CompareOperator operator;

  final RExpression value;
}

final class RCompare extends RExpression {
  const new(this.value, this.operands);

  final RExpression value;

  final List<RCompareOperand> operands;

  @override
  Object? eval(RenderContext context) {
    var left = value.eval(context);

    for (var operand in operands) {
      var right = operand.value.eval(context);

      var result = switch (operand.operator) {
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
}

final class RCondition extends RExpression {
  const new(this.test, this.trueValue, this.falseValue);

  final RExpression test;

  final RExpression trueValue;

  final RExpression? falseValue;

  @override
  Object? eval(RenderContext context) {
    if (boolean(test.eval(context))) {
      return trueValue.eval(context);
    }

    return falseValue?.eval(context);
  }
}

final class RFilter extends RExpression {
  const new(this.name, this.positional, this.named);

  final String name;

  final List<RExpression> positional;

  final Map<Symbol, RExpression> named;

  @override
  Object? eval(RenderContext context) {
    var positional = <Object?>[
      for (var argument in this.positional) argument.eval(context),
    ];

    var named = <Symbol, Object?>{
      for (var entry in this.named.entries)
        entry.key: entry.value.eval(context),
    };

    return context.filter(name, positional, named);
  }
}

final class RGetAttribute extends RExpression {
  const new(this.attribute, this.value);

  final String attribute;

  final RExpression value;

  @override
  Object? eval(RenderContext context) {
    return context.attribute(attribute, value.eval(context));
  }
}

final class RGetItem extends RExpression {
  const new(this.key, this.value);

  final RExpression key;

  final RExpression value;

  @override
  Object? eval(RenderContext context) {
    return context.item(key.eval(context), value.eval(context));
  }
}

final class RGetSlice extends RExpression {
  const new(this.value, this.start, this.stop, this.step);

  final RExpression value;

  final RExpression? start;

  final RExpression? stop;

  final RExpression? step;

  @override
  List<Object?> eval(RenderContext context) {
    var value = this.value.eval(context);
    var start = this.start?.eval(context);
    var stop = this.stop?.eval(context);
    var step = this.step?.eval(context);

    if (value is List && start is int? && stop is int? && step is int?) {
      var increment = step ?? 1;

      var result = <Object?>[];

      if (increment > 0) {
        var begin = start ?? 0;
        var end = stop ?? value.length;

        while (begin < end) {
          result.add(context.item(begin, value));
          begin += increment;
        }
      } else if (increment < 0) {
        var begin = stop ?? value.length - 1;
        var end = start ?? 0;

        while (begin >= end) {
          result.add(context.item(begin, value));
          begin += increment;
        }
      } else {
        throw TemplateRuntimeError('Slice step cannot be zero.');
      }

      return result;
    }

    throw TemplateRuntimeError('Invalid slice operation.');
  }
}

final class RJoin extends RExpression {
  const new(this.values);

  final List<RExpression> values;

  @override
  String eval(RenderContext context) {
    var buffer = StringBuffer();

    for (var value in values) {
      buffer.write(value.eval(context));
    }

    return buffer.toString();
  }
}

final class RList extends RExpression {
  const new(this.list);

  final List<RExpression> list;

  @override
  List<Object?> eval(RenderContext context) {
    return <Object?>[for (var item in list) item.eval(context)];
  }
}

final class RLoad extends RExpression {
  const new(this.name);

  final String name;

  @override
  Object? eval(RenderContext context) {
    return context.resolve(name);
  }
}

final class RLogical extends RExpression {
  const new(this.left, this.right, this.operator);

  final RExpression left;

  final RExpression right;

  final LogicalOperator operator;

  @override
  Object? eval(RenderContext context) {
    var left = this.left.eval(context);

    return switch (operator) {
      LogicalOperator.and => boolean(left) ? right.eval(context) : left,
      LogicalOperator.or => boolean(left) ? left : right.eval(context),
    };
  }
}

final class RMapPair {
  const new(this.key, this.value);

  final RExpression key;

  final RExpression value;
}

final class RMap extends RExpression {
  const new(this.pairs);

  final List<RMapPair> pairs;

  @override
  Map<Object?, Object?> eval(RenderContext context) {
    return <Object?, Object?>{
      for (var pair in pairs) pair.key.eval(context): pair.value.eval(context),
    };
  }
}

final class RName extends RExpression {
  const new(this.name);

  final String name;

  @override
  String eval(RenderContext context) {
    return name;
  }
}

final class RNsRef extends RExpression {
  const new(this.name, this.attribute);

  final String name;

  final String attribute;

  @override
  NamespaceValue eval(RenderContext context) {
    return NamespaceValue(name, attribute);
  }
}

final class RUnary extends RExpression {
  const new(this.value, this.operator);

  final RExpression value;

  final UnaryOperator operator;

  @override
  Object? eval(RenderContext context) {
    var value = this.value.eval(context);

    return switch (operator) {
      UnaryOperator.plus => value,
      // ignore: avoid_dynamic_calls
      UnaryOperator.minus => -(value as dynamic),
      UnaryOperator.not => !boolean(value),
    };
  }
}

final class RScalar extends RExpression {
  const new(this.left, this.right, this.operator);

  final RExpression left;

  final RExpression right;

  final ScalarOperator operator;

  @override
  Object? eval(RenderContext context) {
    var left = this.left.eval(context);

    return switch (operator) {
      ScalarOperator.power => math.pow(left as num, right.eval(context) as num),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.module => (left as dynamic) % right.eval(context),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.floorDivision => (left as dynamic) ~/ right.eval(context),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.division => (left as dynamic) / right.eval(context),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.multiple => (left as dynamic) * right.eval(context),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.minus => (left as dynamic) - right.eval(context),
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      ScalarOperator.plus => (left as dynamic) + right.eval(context),
    };
  }
}

final class RTest extends RExpression {
  const new(this.name, this.positional, this.named);

  final String name;

  final List<RExpression> positional;

  final Map<Symbol, RExpression> named;

  @override
  bool eval(RenderContext context) {
    var positional = <Object?>[
      for (var argument in this.positional) argument.eval(context),
    ];

    var named = <Symbol, Object?>{
      for (var entry in this.named.entries)
        entry.key: entry.value.eval(context),
    };

    return context.test(name, positional, named);
  }
}

final class RValue extends RExpression {
  const new(this.value);

  final Object? value;

  @override
  Object? eval(RenderContext context) {
    return value;
  }
}

// Statements

final class RAssign extends RStatement {
  const new(this.target, this.value);

  final String target;

  final RExpression value;

  @override
  void render(RenderContext context) {
    var value = this.value.eval(context);
    context.assignTargets(target, value);
  }
}

final class RAssignAttribute extends RStatement {
  const new(this.target, this.attribute, this.value);

  final String target;

  final String attribute;

  final RExpression value;

  @override
  void render(RenderContext context) {
    var target = context.resolve(this.target);

    if (target is! Namespace) {
      throw TemplateRuntimeError('Non-namespace object.');
    }

    target[attribute] = value.eval(context);
  }
}

final class RAssignTargets extends RStatement {
  const new(this.target, this.value);

  final RExpression target;

  final RExpression value;

  @override
  void render(RenderContext context) {
    var target = this.target.eval(context);
    var value = this.value.eval(context);
    context.assignTargets(target, value);
  }
}

final class RCallBlock extends RStatement {
  const new(this.name, {this.checkParent = false});

  final String name;

  final bool checkParent;

  @override
  void render(RenderContext context) {
    if (checkParent && context.parentTemplate != null) {
      return;
    }

    context.blocks[name]![0](context);
  }
}

final class RMacroDef {
  const new({
    required this.name,
    required this.positional,
    required this.named,
    required this.accessesCaller,
    required this.accessesKwargs,
    required this.accessesVarargs,
    required this.nodes,
  });

  final String name;

  final List<String> positional;

  final List<(String, RExpression)> named;

  final bool accessesCaller;

  final bool accessesKwargs;

  final bool accessesVarargs;

  final List<RenderNode> nodes;

  MacroFunction createMacro(RenderContext context) {
    String macro(List<Object?> positionalArgs, Map<Symbol, Object?> namedArgs) {
      var buffer = StringBuffer();
      var derived = context.derived(sink: buffer);

      for (var param in positional) {
        derived.set(param, null);
      }

      for (var (param, _) in named) {
        derived.set(param, null);
      }

      var provided = <String>{};
      var totalParams = positional.length + named.length;

      for (var i = 0; i < positionalArgs.length && i < totalParams; i++) {
        String key;

        if (i < positional.length) {
          key = positional[i];
        } else {
          (key, _) = named[i - positional.length];
        }

        derived.set(key, positionalArgs[i]);
        provided.add(key);
      }

      if (positionalArgs.length > totalParams) {
        if (accessesVarargs) {
          derived.set('varargs', positionalArgs.sublist(totalParams));
        } else {
          throw TypeError();
        }
      } else if (accessesVarargs) {
        derived.set('varargs', const <Object?>[]);
      }

      var namedStrings = <String, Object?>{
        for (var entry in namedArgs.entries)
          _symbolToName(entry.key): entry.value,
      };

      var remaining = namedStrings.keys.toSet();

      for (var key in positional) {
        if (remaining.remove(key)) {
          if (provided.contains(key)) {
            throw TypeError();
          }

          derived.set(key, namedStrings[key]);
          provided.add(key);
        } else if (!provided.contains(key)) {
          derived.set(key, context.undefined(key));
        }
      }

      for (var (key, _) in named) {
        if (remaining.remove(key)) {
          if (provided.contains(key)) {
            throw TypeError();
          }

          derived.set(key, namedStrings[key]);
          provided.add(key);
        }
      }

      for (var (key, defaultValue) in named) {
        if (!provided.contains(key)) {
          derived.set(key, defaultValue.eval(derived));
        }
      }

      if (accessesKwargs) {
        derived.set('kwargs', <Object?, Object?>{
          for (var key in remaining) key: namedStrings[key],
        });
      } else if (remaining.isNotEmpty) {
        throw TypeError();
      }

      for (var node in nodes) {
        node.render(derived);
      }

      return buffer.toString();
    }

    return macro;
  }
}

final class RMacro extends RStatement {
  const new(this.def);

  final RMacroDef def;

  @override
  void render(RenderContext context) {
    context.set(def.name, def.createMacro(context));
  }
}

final class RCallerBlock extends RStatement {
  const new(this.call, this.callerDef, {this.checkParent = false});

  final RCall call;

  final RMacroDef callerDef;

  final bool checkParent;

  @override
  void render(RenderContext context) {
    if (checkParent && context.parentTemplate != null) {
      return;
    }

    var function = call.function.eval(context);

    var positional = <Object?>[
      for (var argument in call.positional) argument.eval(context),
    ];

    var named = <Symbol, Object?>{
      for (var entry in call.named.entries)
        entry.key: entry.value.eval(context),
      #caller: callerDef.createMacro(context),
    };

    context.write(context.finalize(context.call(function, positional, named)));
  }
}

final class RDo extends RStatement {
  const new(this.expressions);

  final List<RExpression> expressions;

  @override
  void render(RenderContext context) {
    for (var expression in expressions) {
      expression.eval(context);
    }
  }
}

final class RExtends extends RStatement {
  const new(this.template);

  final RExpression template;

  @override
  void render(RenderContext context) {
    if (context.parentTemplate != null) {
      throw TemplateAssertionError('Extended multiple times.');
    }

    var templateOrPath = template.eval(context);

    var parentTemplate = switch (templateOrPath) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    context.parentTemplate = parentTemplate;
  }
}

final class RFor extends RStatement {
  const new(
    this.target,
    this.iterable,
    this.nodes,
    this.elseNodes, {
    this.test,
    this.recursive = false,
    this.extendedLoop = false,
  });

  final RExpression target;

  final RExpression iterable;

  final List<RenderNode> nodes;

  final List<RenderNode> elseNodes;

  final RExpression? test;

  final bool recursive;

  final bool extendedLoop;

  @override
  void render(RenderContext context) {
    var target = this.target.eval(context);
    var iterable = this.iterable.eval(context);

    if (iterable == null) {
      throw ArgumentError.notNull('iterable');
    }

    String renderLoop(Object? currentIterable, [int depth = 0]) {
      if (currentIterable == null) {
        throw ArgumentError.notNull('iterable');
      }

      List<Object?> values;

      if (currentIterable is Map) {
        values = List<Object?>.of(currentIterable.entries);
      } else {
        values = list(currentIterable);
      }

      if (values.isEmpty) {
        for (var node in elseNodes) {
          node.render(context);
        }

        return '';
      }

      if (test case var test?) {
        var filtered = <Object?>[];

        for (var value in values) {
          var data = context.getDataForTargets(target, value);
          var testContext = context.derived(data: data);

          if (boolean(test.eval(testContext))) {
            filtered.add(value);
          }
        }

        values = filtered;

        if (values.isEmpty) {
          for (var node in elseNodes) {
            node.render(context);
          }

          return '';
        }
      }

      if (extendedLoop) {
        var loop = LoopContext(values, depth, renderLoop);

        for (var value in loop) {
          var data = context.getDataForTargets(target, value);
          var forContext = context.derived(data: data);
          forContext.set('loop', loop);

          for (var node in nodes) {
            node.render(forContext);
          }
        }
      } else {
        for (var value in values) {
          var data = context.getDataForTargets(target, value);
          var forContext = context.derived(data: data);

          for (var node in nodes) {
            node.render(forContext);
          }
        }
      }

      return '';
    }

    renderLoop(iterable);
  }
}

final class RFromImport extends RStatement {
  const new(this.template, this.names, {this.withContext = false});

  final RExpression template;

  final List<(String, String?)> names;

  final bool withContext;

  @override
  void render(RenderContext context) {
    var templateOrPath = this.template.eval(context);

    var template = switch (templateOrPath) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    var importContext = context.derived(
      sink: StringBuffer(),
      template: template.path,
      callerContext: withContext ? context : null,
      withContext: withContext,
    );

    template.renderNode.render(importContext);

    for (var (name, alias) in names) {
      var targetName = alias ?? name;

      if (importContext.context.containsKey(name)) {
        context.set(targetName, importContext.context[name]);
      } else {
        Never missing(List<Object?> positional, Map<Symbol, Object?> named) {
          throw TemplateRuntimeError(
            "The '${template.path}' does not export the requested name.",
          );
        }

        context.set(targetName, missing);
      }
    }
  }
}

final class IfCase {
  const new(this.test, this.nodes);

  final RExpression test;

  final List<RenderNode> nodes;
}

final class RIf extends RStatement {
  const new(this.cases, this.elseNodes);

  final List<IfCase> cases;

  final List<RenderNode> elseNodes;

  @override
  void render(RenderContext context) {
    for (var ifCase in cases) {
      if (boolean(ifCase.test.eval(context))) {
        for (var node in ifCase.nodes) {
          node.render(context);
        }

        return;
      }
    }

    for (var node in elseNodes) {
      node.render(context);
    }
  }
}

final class RImport extends RStatement {
  const new(this.template, this.target, {this.withContext = false});

  final RExpression template;

  final String target;

  final bool withContext;

  @override
  void render(RenderContext context) {
    var templateOrPath = this.template.eval(context);

    var template = switch (templateOrPath) {
      String path => context.environment.getTemplate(path),
      Template template => template,
      Object? value => throw ArgumentError.value(value, 'template'),
    };

    var importContext = context.derived(
      sink: StringBuffer(),
      template: template.path,
      callerContext: withContext ? context : null,
      withContext: withContext,
    );

    template.renderNode.render(importContext);

    var namespace = Namespace(<String, Object?>{
      for (var MapEntry(:key, :value) in importContext.context.entries)
        if (!key.startsWith('_')) key: value,
    });

    context.set(target, namespace);
  }
}

final class RInclude extends RStatement {
  const new(
    this.template, {
    this.ignoreMissing = false,
    this.withContext = true,
  });

  final RExpression template;

  final bool ignoreMissing;

  final bool withContext;

  @override
  void render(RenderContext context) {
    var templateOrPath = this.template.eval(context);

    Template? template;

    try {
      template = switch (templateOrPath) {
        String path => context.environment.getTemplate(path),
        Template template => template,
        List<Object?> paths => context.environment.selectTemplate(paths),
        Iterable<Object?> paths => context.environment.selectTemplate(
          paths.toList(),
        ),
        Object? value => throw ArgumentError.value(value, 'template'),
      };
    } on TemplateNotFound {
      if (!ignoreMissing) {
        rethrow;
      }
    }

    if (template != null) {
      if (withContext) {
        template.renderTo(context.sink, <String, Object?>{
          ...context.parent,
          ...context.context,
        });
      } else {
        template.renderTo(context.sink);
      }
    }
  }
}

final class RTryCatch extends RStatement {
  const new(this.nodes, this.exception, this.catchNodes);

  final List<RenderNode> nodes;

  final String? exception;

  final List<RenderNode> catchNodes;

  @override
  void render(RenderContext context) {
    try {
      for (var node in nodes) {
        node.render(context);
      }
    } catch (error) {
      if (exception case var exception?) {
        context = context.derived(data: <String, Object?>{exception: error});
      }

      for (var node in catchNodes) {
        node.render(context);
      }
    }
  }
}

final class RWith extends RStatement {
  const new(this.targets, this.values, this.nodes);

  final List<RExpression> targets;

  final List<RExpression> values;

  final List<RenderNode> nodes;

  @override
  void render(RenderContext context) {
    var targets = <Object?>[
      for (var target in this.targets) target.eval(context),
    ];
    var values = <Object?>[for (var value in this.values) value.eval(context)];

    var data = context.getDataForTargets(targets, values);
    var withContext = context.derived(data: data);

    for (var node in nodes) {
      node.render(withContext);
    }
  }
}
