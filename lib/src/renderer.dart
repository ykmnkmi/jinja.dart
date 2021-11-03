import 'package:meta/meta.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'utils.dart';
import 'visitor.dart';

class RenderContext extends Context {
  RenderContext(Environment environment, this.sink,
      {Map<String, List<Block>>? blocks,
      Map<String, Object?>? parent,
      Map<String, Object?>? data})
      : blocks = blocks ?? <String, List<Block>>{},
        super(environment, parent: parent, data: data);

  final StringSink sink;

  final Map<String, List<Block>> blocks;

  @override
  RenderContext derived(
      {StringBuffer? buffer,
      Map<String, List<Block>>? blocks,
      Map<String, Object?>? data}) {
    return RenderContext(environment, buffer ?? sink,
        blocks: blocks ?? this.blocks, parent: context, data: data);
  }

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

  @protected
  void assignTargets(Object? target, Object? current) {
    if (target is String) {
      set(target, current);
      return;
    }

    if (target is List<String>) {
      var values = list(current);

      if (values.length < target.length) {
        throw StateError('not enough values to unpack');
      }

      if (values.length > target.length) {
        throw StateError('too many values to unpack');
      }

      for (var i = 0; i < target.length; i++) {
        set(target[i], values[i]);
      }

      return;
    }

    if (target is NamespaceValue) {
      var namespace = resolve(target.name);

      if (namespace is! Namespace) {
        throw TemplateRuntimeError('non-namespace object');
      }

      namespace[target.item] = current;
      return;
    }

    throw TypeError();
  }

  Object? finalize(Object? object) {
    return environment.finalize(this, object);
  }

  void write(Object? object) {
    sink.write(object);
  }
}

class StringSinkRenderer extends Visitor<RenderContext, Object?> {
  @literal
  const StringSinkRenderer();

  @override
  void visitAll(List<Node> nodes, RenderContext context) {
    for (var node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign node, RenderContext context) {
    var target = node.target.resolve(context);
    var values = node.value.resolve(context);
    context.assignTargets(target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, RenderContext context) {
    var target = node.target.resolve(context);
    var buffer = StringBuffer();
    node.body.accept(this, context.derived(buffer: buffer));
    Object? value = buffer.toString();

    var filters = node.filters;

    if (filters == null || filters.isEmpty) {
      context.assignTargets(target, context.escape(value, true));
      return;
    }

    for (var filter in filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.filter(filter.name, positional, named);
      });
    }

    context.assignTargets(target, context.escape(value, true));
  }

  @override
  void visitBlock(Block node, RenderContext context) {
    var blocks = context.blocks[node.name];

    if (blocks == null || blocks.isEmpty) {
      node.body.accept(this, context);
    } else {
      if (node.required) {
        if (blocks.length == 1) {
          var name = node.name;
          throw TemplateRuntimeError('required block \'$name\' not found');
        }
      }

      var first = blocks[0];
      var index = 0;

      if (first.hasSuper) {
        String parent() {
          if (index < blocks.length - 1) {
            var parentBlock = blocks[index += 1];
            parentBlock.body.accept(this, context);
            return '';
          }

          throw TemplateRuntimeError();
        }

        context.set('super', parent);
        first.body.accept(this, context);
        context.remove('super');
      } else {
        first.body.accept(this, context);
      }
    }
  }

  @override
  void visitData(Data node, RenderContext context) {
    context.write(node.data);
  }

  @override
  void visitDo(Do node, RenderContext context) {
    node.expression.resolve(context);
  }

  @override
  void visitExpession(Expression node, RenderContext context) {
    var value = node.resolve(context);
    value = context.escape(value);
    value = context.finalize(value);
    context.write(value);
  }

  @override
  void visitExtends(Extends node, RenderContext context) {
    var template = context.environment.getTemplate(node.path);
    template.accept(this, context);
  }

  @override
  void visitFilterBlock(FilterBlock node, RenderContext context) {
    var buffer = StringBuffer();
    node.body.accept(this, context.derived(buffer: buffer));
    Object? value = '$buffer';

    for (var filter in node.filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.filter(filter.name, positional, named);
      });
    }

    context.write(value);
  }

  @override
  void visitFor(For node, RenderContext context) {
    var targets = node.target.resolve(context);
    var iterable = node.iterable.resolve(context);
    var orElse = node.orElse;

    if (iterable == null) {
      throw TypeError();
    }

    String render(Object? iterable, [int depth = 0]) {
      var values = list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
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

          if (boolean(test.resolve(context))) {
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
  void visitIf(If node, RenderContext context) {
    if (boolean(node.test.resolve(context))) {
      node.body.accept(this, context);
      return;
    }

    var orElse = node.orElse;

    if (orElse != null) {
      orElse.accept(this, context);
    }
  }

  @override
  void visitInclude(Include node, RenderContext context) {
    var template = context.environment.getTemplate(node.template);

    if (node.withContext) {
      template.accept(this, context);
    } else {
      template.accept(this, RenderContext(context.environment, context.sink));
    }
  }

  @override
  Object? visitOutput(Output node, RenderContext context) {
    visitAll(node.nodes, context);
  }

  @override
  void visitScope(Scope node, RenderContext context) {
    node.modifier.accept(this, context);
  }

  @override
  Object? visitScopedContextModifier(
      ScopedContextModifier node, RenderContext context) {
    var data = <String, Object?>{
      for (var entry in node.options.entries)
        entry.key: entry.value.resolve(context)
    };

    data = context.save(data);
    node.body.accept(this, context);
    context.restore(data);
  }

  @override
  void visitTemplate(Template node, RenderContext context) {
    for (var block in node.blocks) {
      var blocks = context.blocks[block.name] ??= <Block>[];
      blocks.add(block);
    }

    if (node.hasSelf) {
      var self = Namespace();

      for (var block in node.blocks) {
        self[block.name] = () {
          block.accept(this, context);
          return '';
        };
      }

      context.set('self', self);
    }

    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, RenderContext context) {
    var expressions = node.targets;
    var targets = generate(expressions, (i) => expressions[i].resolve(context));
    expressions = node.values;
    var values = generate(expressions, (i) => expressions[i].resolve(context));
    var data = context.save(getDataForTargets(targets, values));
    node.body.accept(this, context);
    context.restore(data);
  }

  @protected
  static Map<String, Object?> getDataForTargets(
      Object? targets, Object? current) {
    if (targets is String) {
      return <String, Object?>{targets: current};
    }

    if (targets is List) {
      var names = targets.cast<String>();
      var values = list(current);

      if (values.length < names.length) {
        throw StateError(
            'not enough values to unpack (expected ${names.length}, got ${values.length})');
      }

      if (values.length > names.length) {
        throw StateError(
            'too many values to unpack (expected ${names.length})');
      }

      return <String, Object?>{
        for (var i = 0; i < names.length; i++) names[i]: values[i]
      };
    }

    throw TypeError();
  }
}
