import '../../context.dart';
import '../../parser.dart';
import '../core.dart';
import '../expressions/primary.dart';

class BlockStatement extends Statement {
  static BlockStatement parse(Parser parser) {
    final endBlockReg = parser.getBlockEndRegFor('endblock');

    if (parser.scanner.matches(parser.blockEndReg)) {
      parser.error('block name expected');
    }

    final nameExpr = parser.parsePrimary();

    if (nameExpr is Name) {
      final name = nameExpr.name;

      parser.scanner.expect(parser.blockEndReg);

      final body = parser.parseStatements(<Pattern>[endBlockReg]);

      parser.scanner.expect(endBlockReg);

      return BlockStatement(name, parser.path, body);
    } else {
      parser.error('got ${nameExpr.runtimeType} expect name');
    }
  }

  BlockStatement(this.name, this.path, this.body);

  final String name;
  final String path;
  final Node body;

  @override
  void accept(StringBuffer buffer, Context context) {
    final blockContext = context[BlockContext.contextKey];

    if (toBool(blockContext) && (blockContext  as BlockContext).has(name)) {
      final child = blockContext.pop(name);

      if (child != null) {
        final childContext = <String, Object>{
          'super': () {
            accept(buffer, context);
          },
        };

        context.apply(childContext, (context) {
          child.accept(buffer, context);
        });
      }
    } else {
      body.accept(buffer, context);
    }
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'block $name\n${body.toDebugString(level + 1)}';

  @override
  String toString() => 'Block($name, $path, $body)';
}

class ExtendsStatement extends Statement {
  static ExtendsStatement parse(Parser parser) {
    final path = parser.parsePrimary();

    parser.scanner.expect(parser.blockEndReg);

    final nodes = parser.subParse();
    final blocks = Map.fromEntries(nodes
        .whereType<BlockStatement>()
        .map((node) => MapEntry(node.name, node)));
    return ExtendsStatement(path, blocks);
  }

  ExtendsStatement(this.path, this.blocks);

  final Expression path;
  final Map<String, BlockStatement> blocks;

  @override
  void accept(StringBuffer buffer, Context context) {
    final path = this.path.resolve(context);

    if (path is String) {
      final template = context.environment.getTemplate(path);
      var blockContext = context[BlockContext.contextKey] as BlockContext;

      if (blockContext != null) {
        for (var name in blocks.keys) {
          blockContext.push(name, blocks[name]);
        }
      } else {
        blockContext = BlockContext(blocks);
      }

      context.apply(<String, dynamic>{
        BlockContext.contextKey: blockContext,
      }, (context) {
        template.accept(buffer, context);
      });
    } else {
      // Подробный текст проблемы: путь должен быть строкой
      throw Exception(path.runtimeType);
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('# extends: ${path.toDebugString()}');

    blocks.values.forEach((block) {
      buffer.write('\n${block.toDebugString(level)}');
    });

    return buffer.toString();
  }

  @override
  String toString() => 'Extends($path)';
}

class BlockContext {
  static const String contextKey = '_blockContext';

  BlockContext(Map<String, BlockStatement> blocks)
      : blocks = blocks.map((key, value) =>
            MapEntry<String, List<BlockStatement>>(
                key, <BlockStatement>[value]));

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

      if (blocks[name].isEmpty) {
        blocks.remove(name);
      }

      return block;
    }

    return null;
  }

  @override
  String toString() => repr(blocks);
}
