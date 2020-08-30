import '../../context.dart';
import '../../environment.dart';
import '../../exceptions.dart';
import '../core.dart';

class ExtendsStatement extends Statement {
  ExtendsStatement(this.pathOrTemplate) : blocks = <ExtendedBlockStatement>[];

  final Expression pathOrTemplate;

  final List<ExtendedBlockStatement> blocks;

  @override
  void accept(StringSink outSink, Context context) {
    final pathOrTemplate = this.pathOrTemplate.resolve(context);
    Template template;

    if (pathOrTemplate is Template) {
      template = pathOrTemplate;
    } else if (pathOrTemplate is String) {
      template = context.environment.getTemplate(pathOrTemplate);
    } else {
      throw TemplatesNotFound(pathOrTemplate);
    }

    for (final block in blocks) {
      context.blockContext.push(block.name, block);
    }

    template.accept(outSink, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer..write('# extends: ')..write(pathOrTemplate.toDebugString());

    for (final block in blocks) {
      buffer
        ..writeln()
        ..write(block.toDebugString(level));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'Extends($pathOrTemplate, $blocks)';
  }
}

class BlockStatement extends Statement {
  BlockStatement(this.name, this.body, {this.path, this.scoped = false});

  final String name;

  final Node body;

  final String? path;

  final bool scoped;

  @override
  void accept(StringSink outSink, Context context) {
    final blockContext = context.blockContext;

    if (blockContext.has(name)) {
      final child = blockContext.blocks[name]!.last;

      if (child.hasSuper) {
        final childContext = this.childContext(outSink, context);
        context.apply(childContext, (context) {
          child.accept(outSink, context);
        });
      } else {
        child.accept(outSink, context);
      }
    } else {
      body.accept(outSink, context);
    }
  }

  Map<String, dynamic> childContext(StringSink outSink, Context context) {
    return <String, dynamic>{
      'super': () {
        context.removeLast('super');
        body.accept(outSink, context);
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
      buffer.writeln();
    }

    buffer.write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Block($name, $path, $body)';
  }
}

class ExtendedBlockStatement extends BlockStatement {
  ExtendedBlockStatement(String name, Node body,
      {String? path, bool scoped = false, this.hasSuper = false})
      : super(name, body, path: path, scoped: scoped);

  final bool hasSuper;

  @override
  void accept(StringSink outSink, Context context) {
    final blockContext = context.blockContext;

    if (blockContext.has(name)) {
      final child = blockContext.child(this);

      if (child != null) {
        if (child.hasSuper) {
          final childContext = this.childContext(outSink, context);

          context.apply(childContext, (context) {
            child.accept(outSink, context);
          });

          return;
        }

        child.accept(outSink, context);
        return;
      }
    }

    body.accept(outSink, context);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('block ')
      ..write(name)
      ..write(' [')
      ..write(path)
      ..writeln(']')
      ..write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Block($name, $path, $body)';
  }
}

class ExtendedBlockContext {
  ExtendedBlockContext() : blocks = <String, List<ExtendedBlockStatement>>{};

  final Map<String, List<ExtendedBlockStatement>> blocks;

  bool has(String name) {
    return blocks.containsKey(name);
  }

  void push(String name, ExtendedBlockStatement block) {
    if (blocks.containsKey(name)) {
      blocks[name]!.add(block);
    } else {
      blocks[name] = <ExtendedBlockStatement>[block];
    }
  }

  ExtendedBlockStatement? child(ExtendedBlockStatement current) {
    if (blocks.containsKey(current.name)) {
      final blocks = this.blocks[current.name]!;
      final currentIndex = blocks.indexOf(current);

      if (currentIndex > 0) {
        return blocks[currentIndex - 1];
      }
    }

    return null;
  }

  @override
  String toString() {
    return repr(blocks);
  }
}
