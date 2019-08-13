import '../../context.dart';
import '../../parser.dart';
import '../core.dart';
import '../expressions/primary.dart';
import '../template.dart';

class ExtendsStatement extends Statement {
  static const String containerKey = '__ext-cnt';
  static const String levelKey = '__ext-last-lvl';

  static ExtendsStatement parse(Parser parser) {
    final path = parser.parsePrimary();
    parser.scanner.expect(parser.blockEndReg);

    final extendsStatement = ExtendsStatement(path);

    if (parser.context.containsKey(containerKey)) {
      parser.context[containerKey].add(extendsStatement);
    } else {
      parser.context[containerKey] = [extendsStatement];
    }

    parser.addTemplateModifier((template) {
      final nodes = template.nodes.toList(growable: false);
      template.nodes
        ..clear()
        ..addAll(nodes.sublist(0, 1));
    });

    return extendsStatement;
  }

  ExtendsStatement(this.pathOrTemplate);

  final Expression pathOrTemplate;

  final List<BlockStatement> blocks = <BlockStatement>[];

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

      final body = parser.parseStatementBody([blockEndReg]);

      subscription.cancel();

      parser.notAssignable.remove('super');

      parser.scanner.expect(blockEndReg);

      final block = BlockStatement(name, parser.path, body, hasSuper);

      if (parser.context.containsKey(ExtendsStatement.containerKey)) {
        for (var extendsStatement
            in (parser.context[ExtendsStatement.containerKey]
                as List<ExtendsStatement>)) {
          extendsStatement.blocks.add(block);
        }
      } else {
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
          final childContext = this.childContext(buffer, context);

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

  Map<String, dynamic> childContext(StringBuffer buffer, Context context) {
    return {
      'super': () {
        context.removeLast('super');
        accept(buffer, context);
      }
    };
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
      final block = blocks[name].removeLast();
      if (blocks[name].isEmpty) blocks.remove(name);
      return block;
    }

    return null;
  }

  @override
  String toString() => repr(blocks);
}
