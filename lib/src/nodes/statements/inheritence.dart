import '../../context.dart';
import '../core.dart';
import '../template.dart';

class ExtendsStatement extends Statement {
  static const String containerKey = '__ext-cnt';
  static const String levelKey = '__ext-last-lvl';

  ExtendsStatement(this.pathOrTemplate);

  final Expression pathOrTemplate;

  final List<ExtendedBlockStatement> blocks = <ExtendedBlockStatement>[];

  @override
  void accept(StringBuffer buffer, Context context) {
    final pathOrTemplate = this.pathOrTemplate.resolve(context);

    Template template;

    if (pathOrTemplate is String) {
      template = context.env.getTemplate(pathOrTemplate);
    } else if (pathOrTemplate is Template) {
      template = pathOrTemplate;
    } else {
      // TODO: full path
      throw Exception(pathOrTemplate.runtimeType);
    }

    for (var block in blocks) {
      context.blockContext.push(block.name, block);
    }

    template.accept(buffer, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('# extends: ${pathOrTemplate.toDebugString()}');

    blocks.forEach((block) {
      buffer.write('\n${block.toDebugString(level)}');
    });

    return buffer.toString();
  }

  @override
  String toString() => 'Extends($pathOrTemplate, $blocks)';
}

class BlockStatement extends Statement {
  BlockStatement(this.name, this.path, this.body, [this.scoped = false]);

  final String name;
  final String path;
  final Node body;
  final bool scoped;

  @override
  void accept(StringBuffer buffer, Context context) {
    final blockContext = context.blockContext;

    if (blockContext.has(name)) {
      final child = blockContext.blocks[name].last;

      if (child.hasSuper) {
        final childContext = this.childContext(buffer, context);

        context.apply(childContext, (context) {
          child.accept(buffer, context);
        });
      } else {
        child.accept(buffer, context);
      }
    } else {
      body.accept(buffer, context);
    }
  }

  Map<String, dynamic> childContext(StringBuffer buffer, Context context) {
    return {
      'super': () {
        context.removeLast('super');
        body.accept(buffer, context);
      }
    };
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('block $name');

    if (scoped) {
      buffer.writeln('scoped');
    } else {
      buffer.writeln('scoped');
    }

    buffer.write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() => 'Block($name, $path, $body)';
}

class ExtendedBlockStatement extends BlockStatement {
  ExtendedBlockStatement(
    String name,
    String path,
    Node body, {
    bool scoped = false,
    this.hasSuper = false,
  }) : super(name, path, body, scoped);

  final bool hasSuper;

  @override
  void accept(StringBuffer buffer, Context context) {
    final blockContext = context.blockContext;

    if (blockContext.has(name)) {
      final child = blockContext.child(this);

      if (child != null) {
        if (child.hasSuper) {
          final childContext = this.childContext(buffer, context);

          context.apply(childContext, (context) {
            child.accept(buffer, context);
          });

          return;
        }

        child.accept(buffer, context);
        return;
      }
    }

    body.accept(buffer, context);
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'block $name\n${body.toDebugString(level + 1)}';

  @override
  String toString() => 'Block($name, $path, $body)';
}

class ExtendedBlockContext {
  final Map<String, List<ExtendedBlockStatement>> blocks =
      <String, List<ExtendedBlockStatement>>{};

  bool has(String name) => blocks.containsKey(name);

  void push(String name, ExtendedBlockStatement block) {
    if (blocks.containsKey(name)) {
      blocks[name].add(block);
    } else {
      blocks[name] = <ExtendedBlockStatement>[block];
    }
  }

  ExtendedBlockStatement parent(ExtendedBlockStatement current) {
    if (blocks.containsKey(current.name)) {
      final blocks = this.blocks[current.name];
      final ci = blocks.indexOf(current);

      if (ci >= 0 && ci < blocks.length - 1) {
        return blocks[ci + 1];
      }
    }

    return null;
  }

  ExtendedBlockStatement child(ExtendedBlockStatement current) {
    if (blocks.containsKey(current.name)) {
      final blocks = this.blocks[current.name];
      final ci = blocks.indexOf(current);

      if (ci > 0) {
        return blocks[ci - 1];
      }
    }

    return null;
  }

  @override
  String toString() => repr(blocks);
}
