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
  static Future<TemplateModule> compile(String source,
          {Environment environment}) =>
      Future.value();

  factory Template.parse(String source, {Environment environment}) =>
      Parser(environment ?? Environment(), source).parse();

  Template({
    @required this.body,
    @required this.environment,
    this.path,
  }) {
    _testRender = RenderWrapper(([Map<String, Object> data]) => render(data));
  }

  final Node body;
  final Environment environment;
  final String path;

  dynamic _testRender;
  dynamic get testRender => _testRender;

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

class TemplateModule extends Template {}
