import 'dart:mirrors';

import 'package:meta/meta.dart';

import '../environment.dart';
import '../parser.dart';

import 'core.dart';

class RenderWrapper {
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

/// The central template object. This class represents a compiled template
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
          trimBlocks: trimBlocks,
          leftStripBlocks: leftStripBlocks,
        ),
        source,
      ).parse();

  Template.from({
    @required this.body,
    @required this.environment,
    this.path,
  }) {
    _renderWr = RenderWrapper(([Map<String, Object> data]) => render(data));
  }

  final Node body;
  final Environment environment;
  final String path;

  dynamic _renderWr;
  /** 
   * This is function.
   * For debug.
   * Calls a render function with named arguments:
   *
   *     tmpl.renderWr(key: value, key2: value2)
   *
   * equal
   *
   *     tmpl.render({'key': value, 'key2': value2})
   *
   */
  dynamic get renderWr => _renderWr;

  @override
  void accept(StringBuffer buffer, Context context) {
    body.accept(buffer, context);
  }

  /// If no arguments are given the context will be empty.
  String render([Map<String, Object> data]) {
    final context = Context(context: data, environment: environment);
    final buffer = StringBuffer();
    body.accept(buffer, context);
    return '$buffer';
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
