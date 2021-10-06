import 'package:meta/meta.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'utils.dart' as utils;
import 'visitor.dart';

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

  @protected
  void assignTargets(Object? target, Object? current) {
    if (target is String) {
      set(target, current);
      return;
    }

    if (target is List<String>) {
      var values = utils.list(current);

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

  bool remove(String name) {
    for (var context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  void set(String key, Object? value) {
    contexts.last[key] = value;
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
    visitAll(node.nodes, RenderContext.from(context, buffer));
    Object? value = '$buffer';

    var filters = node.filters;

    if (filters == null || filters.isEmpty) {
      context.assignTargets(target, context.escaped(value));
      return;
    }

    for (var filter in filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.environment
            .callFilter(filter.name, positional, named, context);
      });
    }

    context.assignTargets(target, context.escaped(value));
  }

  @override
  void visitBlock(Block node, RenderContext context) {
    var blocks = context.blocks[node.name];

    if (blocks == null || blocks.isEmpty) {
      visitAll(node.nodes, context);
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
            visitAll(parentBlock.nodes, context);
            return '';
          }

          throw TemplateRuntimeError();
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
  void visitData(Data node, RenderContext context) {
    context.write(node.data);
  }

  @override
  void visitDo(Do node, RenderContext context) {
    for (var node in node.nodes) {
      node.resolve(context);
    }
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
    visitAll(node.nodes, RenderContext.from(context, buffer));
    Object? value = '$buffer';

    for (var filter in node.filters) {
      value = filter.apply(context, (positional, named) {
        positional.insert(0, value);
        return context.environment
            .callFilter(filter.name, positional, named, context);
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
      var values = utils.list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, context);
        }

        return '';
      }

      if (node.test != null) {
        var test = node.test!;
        var filtered = <Object?>[];

        for (var value in values) {
          var data = getDataForTargets(targets, value);
          context.push(data);

          if (utils.boolean(test.resolve(context))) {
            filtered.add(value);
          }

          context.pop();
        }

        values = filtered;
      }

      var loop = LoopContext(values, depth, render);
      Map<String, Object?> Function(Object?, Object?) unpack;

      if (node.hasLoop) {
        unpack = (Object? target, Object? value) {
          var data = getDataForTargets(target, value);
          data['loop'] = loop;
          return data;
        };
      } else {
        unpack = getDataForTargets;
      }

      for (var value in loop) {
        var data = unpack(targets, value);
        context.push(data);
        visitAll(node.nodes, context);
        context.pop();
      }

      return '';
    }

    render(iterable);
  }

  @override
  void visitIf(If node, RenderContext context) {
    if (utils.boolean(node.test.resolve(context))) {
      visitAll(node.nodes, context);
      return;
    }

    var next = node.nextIf;

    while (next != null) {
      if (utils.boolean(next.test.resolve(context))) {
        visitAll(next.nodes, context);
        return;
      }

      next = next.nextIf;
    }

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
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

    context.push(data);
    visitAll(node.nodes, context);
    context.pop();
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
    var targets =
        node.targets.map<Object?>((target) => target.resolve(context)).toList();
    var values =
        node.values.map<Object?>((value) => value.resolve(context)).toList();
    context.push(getDataForTargets(targets, values));
    visitAll(node.nodes, context);
    context.pop();
  }

  @protected
  static Map<String, Object?> getDataForTargets(
      Object? targets, Object? current) {
    if (targets is String) {
      return <String, Object?>{targets: current};
    }

    if (targets is List) {
      var names = targets.cast<String>();
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

    throw TypeError();
  }
}
