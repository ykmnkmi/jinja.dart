import 'dart:mirrors';

import 'package:meta/meta.dart';

import '../environment.dart';
import '../namespace.dart';
import '../parser.dart';
import '../utils.dart';

import 'core.dart';
import 'statements/inheritence.dart';

typedef void ContextModifier(Context context);

/// The central `Template` object. This class represents a compiled template
/// and is used to evaluate it.
///
/// Normally the template is generated from `Environment` but
/// it also has a constructor that makes it possible to create a template
/// instance directly using the constructor.  It takes the same arguments as
/// the environment constructor but it's not possible to specify a loader.
class Template extends Node {
  // TODO: compile template

  factory Template(
    String source, {
    String blockStart = '{%',
    String blockEnd = '%}',
    String variableStart = '{{',
    String variableEnd = '}}',
    String commentStart = '{#',
    String commentEnd = '#}',
    bool autoEscape = false,
    bool trimBlocks = false,
    bool leftStripBlocks = false,
  }) =>
      Parser(
        Environment(
          blockStart: blockStart,
          blockEnd: blockEnd,
          variableStart: variableStart,
          variableEnd: variableEnd,
          commentStart: commentStart,
          commentEnd: commentEnd,
          autoEscape: autoEscape,
          trimBlocks: trimBlocks,
          leftStripBlocks: leftStripBlocks,
        ),
        source,
      ).parse();

  Template.from({@required this.body, @required this.env, this.path})
      : blocks = <String, BlockStatement>{} {
    _render = RenderWrapper(([Map<String, Object> data]) => renderMap(data));
  }

  final Node body;
  final Environment env;
  final String path;
  final Map<String, BlockStatement> blocks;

  dynamic _render;
  Function get render => _render as Function;

  void setContext(StringBuffer buffer, Context context) {
    final self = NameSpace();

    for (var blockEntry in blocks.entries) {
      self[blockEntry.key] = () {
        blockEntry.value.accept(buffer, context);
      };
    }

    context.contexts.first['self'] = self;
  }

  @override
  void accept(StringBuffer buffer, Context context) {
    setContext(buffer, context);
    body.accept(buffer, context);
  }

  String renderMap([Map<String, Object> data]) {
    final buffer = StringBuffer();
    final context = Context(data: data, env: env);
    setContext(buffer, context);
    body.accept(buffer, context);
    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer();

    if (path != null) {
      buffer.writeln(' ' * level + '# template: ${repr(path)}');
    }

    buffer.write(body.toDebugString(level));
    return buffer.toString();
  }

  @override
  String toString() => 'Template($path, $body)';
}

class RenderWrapper extends Function {
  RenderWrapper(this.function);

  final Function function;

  dynamic call() => function();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.namedArguments
          .map((key, value) => MapEntry(MirrorSystem.getName(key), value)));
    }

    return super.noSuchMethod(invocation);
  }
}
