import 'package:meta/meta.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'runtime.dart';
import 'utils.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink,
      {Map<String, Object?>? data})
      : blocks = <String, List<Block>>{},
        super(environment, data);

  RenderContext.from(Context context, this.sink)
      : blocks = <String, List<Block>>{},
        super.from(context);

  final StringSink sink;

  final Map<String, List<Block>> blocks;

  Object? finalize(Object? object) {
    return environment.finalize(this, object);
  }

  bool remove(String name) {
    for (final context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  void set(String key, Object? value) {
    contexts.last[key] = value is Undefined ? null : value;
  }

  void write(Object? object) {
    sink.write(object);
  }
}

class StringSinkRenderer extends ExpressionResolver<RenderContext> {
  @literal
  const StringSinkRenderer();

  @override
  void visitAll(List<Node> nodes, [RenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign node, [RenderContext? context]) {
    context!;

    final target = node.target.accept(this, context);
    final values = node.expression.accept(this, context);
    assignTargetsToContext(context, target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, [RenderContext? context]) {
    context!;

    final target = node.target.accept(this, context);
    final buffer = StringBuffer();
    visitAll(node.nodes, RenderContext.from(context, buffer));
    Object? value = '$buffer';

    if (node.filters == null || node.filters!.isEmpty) {
      assignTargetsToContext(context, target, context.escaped(value));
      return;
    }

    for (final filter in node.filters!) {
      value = callFilter(filter, value, context);
    }

    assignTargetsToContext(context, target, context.escaped(value));
  }

  @override
  void visitBlock(Block node, [RenderContext? context]) {
    final blocks = context!.blocks[node.name];

    if (blocks == null || blocks.isEmpty) {
      visitAll(node.nodes, context);
    } else {
      if (node.required) {
        if (blocks.length == 1) {
          throw TemplateSyntaxError(
              'required block \'${node.name}\' not found');
        }
      }

      final first = blocks[0];
      var index = 0;

      if (first.hasSuper) {
        // TODO: void call
        String parent() {
          if (index < blocks.length - 1) {
            final parentBlock = blocks[++index];
            visitAll(parentBlock.nodes, context);
            return '';
          }

          // TODO: update error
          throw Exception([blocks, node, index, blocks.length]);
        }

        context.push(<String, Object?>{'super': parent});
        visitAll(first.nodes, context);
        context.pop();
      } else {
        visitAll(first.nodes, context);
      }
    }
  }

  @override
  void visitDo(Do node, [RenderContext? context]) {
    final doContext = Context.from(context!);

    for (final expression in node.expressions) {
      expression.accept(this, doContext);
    }
  }

  @override
  void visitExtends(Extends node, [RenderContext? context]) {
    final template = context!.environment.getTemplate(node.path);
    template.accept(this, context);
  }

  @override
  void visitFilterBlock(FilterBlock node, [RenderContext? context]) {
    context!;

    final buffer = StringBuffer();
    visitAll(node.body, RenderContext.from(context, buffer));
    final value = callFilter(node.filter, '$buffer', context);
    context.write(value);
  }

  @override
  void visitFor(For node, [RenderContext? context]) {
    context!;

    final targets = node.target.accept(this, context);
    final iterable = node.iterable.accept(this, context);
    final orElse = node.orElse;

    if (iterable == null) {
      throw TypeError();
    }

    // TODO: void call
    String recurse(Object? iterable, [int depth = 0]) {
      var values = list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, context);
        }

        return '';
      }

      if (node.test != null) {
        final test = node.test!;
        final filtered = <Object?>[];

        for (final value in values) {
          final data = getDataForTargets(targets, value);
          context.push(data);

          if (test.accept(this, context) as bool) {
            filtered.add(value);
          }

          context.pop();
        }

        values = filtered;
      }

      final loop = LoopContext(values, context.environment.undefined,
          depth0: depth, recurse: recurse);
      Map<String, Object?> Function(Object?, Object?) unpack;

      if (node.hasLoop) {
        unpack = (Object? target, Object? value) {
          final data = getDataForTargets(target, value);
          data['loop'] = loop;
          return data;
        };
      } else {
        unpack = getDataForTargets;
      }

      for (final value in loop) {
        final data = unpack(targets, value);
        context.push(data);
        visitAll(node.body, context);
        context.pop();
      }

      return '';
    }

    recurse(iterable);
  }

  @override
  void visitIf(If node, [RenderContext? context]) {
    context!;

    if (boolean(node.test.accept(this, context))) {
      visitAll(node.body, context);
      return;
    }

    var next = node.nextIf;

    while (next != null) {
      if (boolean(next.test.accept(this, context))) {
        visitAll(next.body, context);
        return;
      }

      next = next.nextIf;
    }

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }
  }

  @override
  void visitInclude(Include node, [RenderContext? context]) {
    final template = context!.environment.getTemplate(node.template);

    if (node.withContext) {
      template.accept(this, context);
    } else {
      template.accept(this, RenderContext(context.environment, context.sink));
    }
  }

  @override
  void visitOutput(Output node, [RenderContext? context]) {
    context!;

    for (final item in node.nodes) {
      if (item is Data) {
        context.write(item.accept(this, context));
      } else {
        var value = item.accept(this, context);
        value = context.escape(value);
        value = context.finalize(value);
        context.write(value);
      }
    }
  }

  @override
  void visitScope(Scope node, [RenderContext? context]) {
    node.modifier.accept(this, context);
  }

  @override
  void visitScopedContextModifier(ScopedContextModifier node,
      [RenderContext? context]) {
    context!;

    final data = <String, Object?>{
      for (final key in node.options.keys)
        key: node.options[key]!.accept(this, context)
    };
    context.push(data);
    visitAll(node.nodes, context);
    context.pop();
  }

  @override
  void visitTemplate(Template node, [RenderContext? context]) {
    context!;

    for (final block in node.blocks) {
      if (!context.blocks.containsKey(block.name)) {
        context.blocks[block.name] = <Block>[];
      }

      context.blocks[block.name]!.add(block);
    }

    if (node.hasSelf) {
      final self = NameSpace();

      for (final block in node.blocks) {
        self.context[block.name] = () {
          // TODO: void call
          block.accept(this, context);
          return '';
        };
      }

      context.set('self', self);
    }

    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, [RenderContext? context]) {
    context!;

    final targets = <Object?>[
      for (final target in node.targets) target.accept(this, context)
    ];
    final values = <Object?>[
      for (final value in node.values) value.accept(this, context)
    ];
    context.push(getDataForTargets(targets, values));
    visitAll(node.body, context);
    context.pop();
  }

  @protected
  static void assignTargetsToContext(
      RenderContext context, Object? target, Object? current) {
    if (target is String) {
      context.set(target, current);
      return;
    }

    if (target is List<String>) {
      List<Object?> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable<Object?>) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < target.length) {
        throw StateError(
            'not enough values to unpack (expected ${target.length}, got ${list.length})');
      }

      if (list.length > target.length) {
        throw StateError(
            'too many values to unpack (expected ${target.length})');
      }

      for (var i = 0; i < target.length; i++) {
        context.set(target[i], list[i]);
      }

      return;
    }

    if (target is NameSpaceValue) {
      final namespace = context[target.name];

      if (namespace is! NameSpace) {
        throw TemplateRuntimeError('non-namespace object');
      }

      namespace[target.item] = current;
      return;
    }

    throw ArgumentError.value(target, 'target');
  }

  @protected
  static Map<String, Object?> getDataForTargets(
      Object? target, Object? current) {
    if (target is String) {
      return <String, Object?>{target: current};
    }

    if (target is List) {
      final names = target.cast<String>();
      List<Object?> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < names.length) {
        throw StateError(
            'not enough values to unpack (expected ${names.length}, got ${list.length})');
      }

      if (list.length > names.length) {
        throw StateError(
            'too many values to unpack (expected ${names.length})');
      }

      return <String, Object?>{
        for (var i = 0; i < names.length; i++) names[i]: list[i]
      };
    }

    throw ArgumentError.value(target, 'target');
  }
}
