import 'context.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'markup.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'utils.dart';
import 'visitor.dart';

class RenderContext extends Context {
  RenderContext(Environment environment,
      {Map<String, List<Block>>? blocks,
      Map<String, Object?>? parent,
      Map<String, Object?>? data})
      : blocks = blocks ?? <String, List<Block>>{},
        super(environment, parent: parent, data: data);

  final Map<String, List<Block>> blocks;

  @override
  RenderContext derived(
      {Map<String, List<Block>>? blocks, Map<String, Object?>? data}) {
    return RenderContext(environment,
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

  Object? finalize(Object? object) {
    return environment.wrappedFinalize(this, object);
  }

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
}

class IterableRenderer extends Visitor<RenderContext, Iterable<String>> {
  const IterableRenderer();

  @override
  Iterable<String> visitAll(List<Node> nodes, RenderContext context) sync* {
    for (var node in nodes) {
      yield* node.accept(this, context);
    }
  }

  @override
  Iterable<String> visitAssign(Assign node, RenderContext context) sync* {
    var target = node.target.resolve(context);
    var values = node.value.resolve(context);
    context.assignTargets(target, values);
  }

  @override
  Iterable<String> visitAssignBlock(
      AssignBlock node, RenderContext context) sync* {
    var target = node.target.resolve(context);
    Object? value = node.body.accept(this, context.derived()).join();

    var filters = node.filters;

    if (filters == null || filters.isEmpty) {
      if (context.autoEscape) {
        value = Markup.escaped(value);
      }

      context.assignTargets(target, value);
      return;
    }

    for (var filter in filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.filter(filter.name, positional, named);
      });
    }

    if (context.autoEscape) {
      value = Markup.escaped(value);
    }

    context.assignTargets(target, value);
  }

  @override
  Iterable<String> visitAutoEscape(
      AutoEscape node, RenderContext context) sync* {
    var current = context.autoEscape;
    context.autoEscape = boolean(node.value.resolve(context));
    yield* node.body.accept(this, context);
    context.autoEscape = current;
  }

  @override
  Iterable<String> visitBlock(Block node, RenderContext context) sync* {
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
            return parentBlock.body.accept(this, context).join();
          }

          throw TemplateRuntimeError();
        }

        context.set('super', parent);
        yield* first.body.accept(this, context);
        context.remove('super');
      } else {
        yield* first.body.accept(this, context);
      }
    }
  }

  @override
  Iterable<String> visitData(Data node, RenderContext context) sync* {
    yield node.data;
  }

  @override
  Iterable<String> visitDo(Do node, RenderContext context) sync* {
    node.expression.resolve(context);
  }

  @override
  Iterable<String> visitExpession(
      Expression node, RenderContext context) sync* {
    var value = context.finalize(node.resolve(context));
    yield context.escape(value).toString();
  }

  @override
  Iterable<String> visitExtends(Extends node, RenderContext context) sync* {
    var template = context.environment.getTemplate(node.path);
    yield* template.accept(this, context);
  }

  @override
  Iterable<String> visitFilterBlock(
      FilterBlock node, RenderContext context) sync* {
    Object? value = node.body.accept(this, context.derived()).join();

    for (var filter in node.filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.filter(filter.name, positional, named);
      });
    }

    yield context.escape(value).toString();
  }

  @override
  Iterable<String> visitFor(For node, RenderContext context) sync* {
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
          return orElse.accept(this, context).join();
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

      var buffer = StringBuffer();

      for (var value in loop) {
        var data = getDataForTargets(targets, value);
        var forContext = context.derived(data: data);
        buffer.writeAll(node.body.accept(this, forContext));
      }

      context.set('loop', parent);
      return buffer.toString();
    }

    yield render(iterable);
  }

  @override
  Iterable<String> visitIf(If node, RenderContext context) sync* {
    if (boolean(node.test.resolve(context))) {
      yield* node.body.accept(this, context);
      return;
    }

    var orElse = node.orElse;

    if (orElse != null) {
      yield* orElse.accept(this, context);
    }
  }

  @override
  Iterable<String> visitInclude(Include node, RenderContext context) sync* {
    var template = context.environment.getTemplate(node.template);

    if (node.withContext) {
      yield* template.accept(this, context);
      return;
    }

    context = RenderContext(context.environment);
    yield* template.accept(this, context);
  }

  @override
  Iterable<String> visitOutput(Output node, RenderContext context) sync* {
    yield* visitAll(node.nodes, context);
  }

  @override
  Iterable<String> visitTemplate(Template node, RenderContext context) sync* {
    var self = Namespace();

    for (var block in node.blocks) {
      var blocks = context.blocks[block.name] ??= <Block>[];
      self[block.name] = () => block.accept(this, context).join();
      blocks.add(block);
    }

    context.set('self', self);
    yield* visitAll(node.nodes, context);
  }

  @override
  Iterable<String> visitWith(With node, RenderContext context) sync* {
    var targets = List<Object?>.generate(
        node.targets.length, (i) => node.targets[i].resolve(context));
    var values = List<Object?>.generate(
        node.values.length, (i) => node.values[i].resolve(context));
    var data = context.save(getDataForTargets(targets, values));
    yield* node.body.accept(this, context);
    context.restore(data);
  }
}

class StringSinkRenderContext extends RenderContext {
  StringSinkRenderContext(Environment environment, this.sink,
      {Map<String, List<Block>>? blocks,
      Map<String, Object?>? parent,
      Map<String, Object?>? data})
      : super(environment, blocks: blocks, parent: parent, data: data);

  final StringSink sink;

  @override
  StringSinkRenderContext derived(
      {StringBuffer? buffer,
      Map<String, List<Block>>? blocks,
      Map<String, Object?>? data}) {
    return StringSinkRenderContext(environment, buffer ?? sink,
        blocks: blocks ?? this.blocks, parent: context, data: data);
  }

  void write(Object? object) {
    sink.write(object);
  }
}

class StringSinkRenderer extends Visitor<StringSinkRenderContext, void> {
  const StringSinkRenderer();

  @override
  void visitAll(List<Node> nodes, StringSinkRenderContext context) {
    for (var node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign node, StringSinkRenderContext context) {
    var target = node.target.resolve(context);
    var values = node.value.resolve(context);
    context.assignTargets(target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, StringSinkRenderContext context) {
    var target = node.target.resolve(context);
    var buffer = StringBuffer();
    node.body.accept(this, context.derived(buffer: buffer));

    Object? value = buffer.toString();
    var filters = node.filters;

    if (filters == null || filters.isEmpty) {
      if (context.autoEscape) {
        value = Markup.escaped(value);
      }

      context.assignTargets(target, context.escape(value));
      return;
    }

    for (var filter in filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.filter(filter.name, positional, named);
      });
    }

    if (context.autoEscape) {
      value = Markup.escaped(value);
    }

    context.assignTargets(target, context.escape(value));
  }

  @override
  void visitAutoEscape(AutoEscape node, StringSinkRenderContext context) {
    var current = context.autoEscape;
    context.autoEscape = boolean(node.value.resolve(context));
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
  void visitData(Data node, StringSinkRenderContext context) {
    context.write(node.data);
  }

  @override
  void visitDo(Do node, StringSinkRenderContext context) {
    node.expression.resolve(context);
  }

  @override
  void visitExpession(Expression node, StringSinkRenderContext context) {
    var value = node.resolve(context);
    value = context.finalize(value);
    value = context.escape(value);
    context.write(value);
  }

  @override
  void visitExtends(Extends node, StringSinkRenderContext context) {
    var template = context.environment.getTemplate(node.path);
    template.accept(this, context);
  }

  @override
  void visitFilterBlock(FilterBlock node, StringSinkRenderContext context) {
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
  void visitFor(For node, StringSinkRenderContext context) {
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
  void visitIf(If node, StringSinkRenderContext context) {
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
  void visitInclude(Include node, StringSinkRenderContext context) {
    var template = context.environment.getTemplate(node.template);

    if (node.withContext) {
      template.accept(this, context);
    } else {
      context = StringSinkRenderContext(context.environment, context.sink);
      template.accept(this, context);
    }
  }

  @override
  void visitOutput(Output node, StringSinkRenderContext context) {
    visitAll(node.nodes, context);
  }

  @override
  void visitTemplate(Template node, StringSinkRenderContext context) {
    var self = Namespace();

    for (var block in node.blocks) {
      var blocks = context.blocks[block.name] ??= <Block>[];
      blocks.add(block);
      self[block.name] = () {
        block.accept(this, context);
        return '';
      };
    }

    context.set('self', self);
    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, StringSinkRenderContext context) {
    var targets = List<Object?>.generate(
        node.targets.length, (i) => node.targets[i].resolve(context));
    var values = List<Object?>.generate(
        node.values.length, (i) => node.values[i].resolve(context));
    var data = context.save(getDataForTargets(targets, values));
    node.body.accept(this, context);
    context.restore(data);
  }
}

Map<String, Object?> getDataForTargets(Object? targets, Object? current) {
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
      throw StateError('too many values to unpack (expected ${names.length})');
    }

    return <String, Object?>{
      for (var i = 0; i < names.length; i++) names[i]: values[i]
    };
  }

  throw TypeError();
}
