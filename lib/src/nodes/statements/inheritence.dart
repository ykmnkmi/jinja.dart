import '../../context.dart';
import '../../parser.dart';
import '../core.dart';
import '../expressions/primary.dart';
import '../template.dart';

class ExtendsStatement extends Statement {
  static const String key = 'extended';

  static ExtendsStatement parse(Parser parser) {
    final path = parser.parsePrimary();

    parser.scanner.expect(parser.blockEndReg);

    final nodes = parser.subParse();
    final blocks = nodes.whereType<BlockStatement>().toList(growable: false);
    parser.context[key] = null;
    return ExtendsStatement(path, blocks);
  }

  ExtendsStatement(this.pathOrTemplate, this.blocks);

  final Expression pathOrTemplate;
  final List<BlockStatement> blocks;

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
  String toString() => 'Extends($pathOrTemplate)';
}

class BlockStatement extends Statement {
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

      if (!parser.context.containsKey(ExtendsStatement.key)) {
        parser.addTemplateModifier((template) {
          template.blocks[block.name] = block;
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
    final blockContext = context.blockContext;

    if (blockContext.has(name)) {
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

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + 'block $name\n${body.toDebugString(level + 1)}';

  @override
  String toString() => 'Block($name, $path, $body)';
}

class BlockContext {
  final Map<String, List<BlockStatement>> blocks =
      <String, List<BlockStatement>>{};

  bool has(String name) => blocks.containsKey(name);

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
