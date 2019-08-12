import '../../context.dart';
import '../../namespace.dart';
import '../../parser.dart';
import '../../undefined.dart';
import '../core.dart';
import '../expressions/primary.dart';

class ExtendsStatement extends Statement {
  static const String contextKey = '_extended';

  static ExtendsStatement parse(Parser parser) {
    final path = parser.parsePrimary();

    parser.scanner.expect(parser.blockEndReg);

    final nodes = parser.subParse();
    final blocks = nodes.whereType<BlockStatement>().toList(growable: false);

    parser.context[contextKey] = null;
    return ExtendsStatement(path, blocks);
  }

  ExtendsStatement(this.path, this.blocks);

  final Expression path;
  final List<BlockStatement> blocks;

  @override
  void accept(StringBuffer buffer, Context context) {
    final path = this.path.resolve(context);

    if (path is String) {
      final template = context.env.getTemplate(path);
      var blockContext = context[BlockContext.contextKey];

      if (blockContext != null && blockContext is! Undefined) {
        for (var block in blocks) {
          blockContext.push(block.name, block);
        }
      } else {
        blockContext = BlockContext(blocks);
      }

      context.apply({BlockContext.contextKey: blockContext}, (context) {
        template.accept(buffer, context);
      });
    } else {
      // TODO: full path
      throw Exception(path.runtimeType);
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('# extends: ${path.toDebugString()}');

    blocks.forEach((block) {
      buffer.write('\n${block.toDebugString(level)}');
    });

    return buffer.toString();
  }

  @override
  String toString() => 'Extends($path)';
}

class BlockStatement extends Statement {
  static const String contextKey = '_blocks';

  static void addBlock(NameSpace nameSpace, BlockStatement block) {
    nameSpace[block.name] = block.render;
  }

  static BlockStatement parse(Parser parser) {
    final blockEndReg = parser.getBlockEndRegFor('endblock');

    if (parser.scanner.matches(parser.blockEndReg)) {
      parser.error('block name expected');
    }

    final nameExpr = parser.parsePrimary();

    if (nameExpr is Name) {
      final name = nameExpr.name;
      var hasSuper = false;

      parser.scanner.expect(parser.blockEndReg);

      parser.notAssignable.add('super');

      final subscription = parser.onParseName.listen((node) {
        if (node.name == 'super') hasSuper = true;
      });

      final body = parser.parseStatements([blockEndReg]);

      subscription.cancel();

      parser.notAssignable.remove('super');

      parser.scanner.expect(blockEndReg);

      final block = BlockStatement(name, parser.path, body, hasSuper);

      if (!parser.context.containsKey(ExtendsStatement.contextKey)) {
        parser.addTemplateModifier((template) {
          addBlock(template.nameSpace, block);
        });
      }

      return block;
    } else {
      parser.error('got ${nameExpr.runtimeType} expect name');
    }
  }

  BlockStatement(this.name, this.path, this.body, [this.hasSuper = false]);

  final String name;
  final String path;
  final Node body;
  final bool hasSuper;

  @override
  void accept(StringBuffer buffer, Context context) {
    final blockContext = context[BlockContext.contextKey];

    if (blockContext != null &&
        blockContext is BlockContext &&
        blockContext.has(name)) {
      final child = blockContext.pop(name);

      if (child != null) {
        if (child.hasSuper) {
          final childContext = this.childContext(context);

          context.apply(childContext, (context) {
            child.accept(buffer, context);
          });
        } else {
          child.accept(buffer, context);
        }
      }
    } else {
      body.accept(buffer, context);
    }
  }

  Map<String, dynamic> childContext(Context context) {
    final buffer = StringBuffer();
    accept(buffer, context);
    final superContent = buffer.toString();
    return {'super': () => superContent};
  }

  String render([Context context]) {
    final buffer = StringBuffer();
    accept(buffer, context ?? Context());
    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'block $name\n${body.toDebugString(level + 1)}';

  @override
  String toString() => 'Block($name, $path, $body)';
}

class BlockContext {
  static const String contextKey = '_block_context';

  BlockContext(List<BlockStatement> blocks)
      : blocks = Map.fromEntries(blocks.map((block) =>
            MapEntry<String, List<BlockStatement>>(
                block.name, <BlockStatement>[block])));

  final Map<String, List<BlockStatement>> blocks;

  bool has(String name) => blocks.containsKey(name) && blocks[name].isNotEmpty;

  void push(String name, BlockStatement block) {
    if (blocks.containsKey(name)) {
      blocks[name].add(block);
    } else {
      blocks[name] = <BlockStatement>[block];
    }
  }

  BlockStatement pop(String name) {
    if (blocks.containsKey(name)) {
      final block = blocks[name].removeAt(0);
      if (blocks[name].isEmpty) blocks.remove(name);
      return block;
    }

    return null;
  }

  @override
  String toString() => repr(blocks);
}
