import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'defaults.dart';
import 'loaders.dart';
import 'namespace.dart';
import 'nodes.dart';
import 'parser.dart';
import 'undefined.dart';

typedef dynamic Finalizer(dynamic value);
dynamic _defaultFinalizer(dynamic value) => value ?? '';

Finalizer _getFinalizer(Finalizer finalize) {
  return (value) {
    value = finalize(value);
    if (value is! String) return repr(value, false);
    return value;
  };
}

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
///
/// Modifications on environments after the first template was loaded
/// will lead to surprising effects and undefined behavior.
@immutable
class Environment {
  /// If `loader` is not `null`, templates will be loaded
  factory Environment({
    String blockStart = '{%',
    String blockEnd = '%}',
    String variableStart = '{{',
    String variableEnd = '}}',
    String commentStart = '{#',
    String commentEnd = '#}',
    bool autoEscape = false,
    bool trimBlocks = false,
    bool leftStripBlocks = false,
    Finalizer finalize = _defaultFinalizer,
    Loader loader,
    bool optimize = true,
    Undefined undefined = const Undefined(),
    Set<Extension> extensions = const <Extension>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, dynamic> globals = const <String, dynamic>{},
  }) {
    final env = Environment._(
      blockStart: blockStart,
      blockEnd: blockEnd,
      variableStart: variableStart,
      variableEnd: variableEnd,
      commentStart: commentStart,
      commentEnd: commentEnd,
      autoEscape: autoEscape,
      trimBlocks: trimBlocks,
      leftStripBlocks: leftStripBlocks,
      finalize: _getFinalizer(finalize),
      optimize: optimize,
      undefined: undefined,
      extensions: extensions,
      filters: Map.of(defaultFilters)..addAll(filters),
      tests: Map.of(defaultTests)..addAll(tests),
      globals: Map.of(defaultContext)..addAll(globals),
    );

    if (loader != null) loader.load(env);
    return env;
  }

  Environment._({
    this.blockStart,
    this.blockEnd,
    this.variableStart,
    this.variableEnd,
    this.commentStart,
    this.commentEnd,
    this.autoEscape,
    this.trimBlocks,
    this.leftStripBlocks,
    this.finalize,
    this.optimize,
    this.shared,
    this.undefined,
    this.extensions = const <Extension>{},
    this.filters = const <String, Function>{},
    this.tests = const <String, Function>{},
    this.globals = const <String, dynamic>{},
  });

  final String blockStart;
  final String blockEnd;
  final String variableStart;
  final String variableEnd;
  final String commentStart;
  final String commentEnd;
  final bool autoEscape;
  final bool trimBlocks;
  final bool leftStripBlocks;
  final Finalizer finalize;
  final Undefined undefined;
  final bool optimize;
  final bool shared;
  final Set<Extension> extensions;
  final Map<String, Function> filters;
  final Map<String, Function> tests;
  final Map<String, dynamic> globals;

  final Map<String, Template> templates = <String, Template>{};

  // TODO(env): compile templates
  // Future<void> compileTemplates() async {}

  /// If `path` is not `null` template stored in environment cache.
  Template fromString(String source, {String path}) {
    final template = Parser(this, source, path: path).parse();
    if (path != null) templates[path] = template;
    return template;
  }

  /// If [path] not found throws `Exception`.
  Template getTemplate(String path) {
    if (!templates.containsKey(path)) {
      throw Exception('Template not found: $path');
    }

    return templates[path];
  }

  /// If [name] not found throws [Exception].
  dynamic callFilter(
    String name, {
    List args = const [],
    Map<Symbol, dynamic> kwargs = const <Symbol, dynamic>{},
  }) {
    if (!filters.containsKey(name)) {
      throw Exception('Filter not found: $name');
    }

    return Function.apply(filters[name], args, kwargs);
  }

  /// If [name] not found throws [Exception].
  bool callTest(
    String name, {
    List args = const [],
    Map<Symbol, dynamic> kwargs = const <Symbol, dynamic>{},
  }) {
    if (!tests.containsKey(name)) {
      throw Exception('Test not found: $name');
    }

    // ignore: return_of_invalid_type
    return Function.apply(tests[name], args, kwargs);
  }
}

typedef void ContextModifier(Context context);

/// The central `Template` object. This class represents a compiled template
/// and is used to evaluate it.
///
/// Normally the template is generated from `Environment` but
/// it also has a constructor that makes it possible to create a template
/// instance directly using the constructor.  It takes the same arguments as
/// the environment constructor but it's not possible to specify a loader.
class Template extends Node {
  static final Map<List, Environment> _shared = <List, Environment>{};

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
    Finalizer finalize = _defaultFinalizer,
    Loader loader,
    bool optimize = true,
    Undefined undefined = const Undefined(),
    Set<Extension> extensions = const <Extension>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, dynamic> globals = const <String, dynamic>{},
  }) {
    final list = [
      blockStart,
      blockEnd,
      variableStart,
      variableEnd,
      commentStart,
      commentEnd,
      autoEscape,
      trimBlocks,
      leftStripBlocks,
      finalize,
      optimize,
      undefined,
      extensions,
      filters,
      tests,
      globals,
    ];

    final env = _shared.containsKey(list)
        ? _shared[list]
        : Environment._(
            blockStart: blockStart,
            blockEnd: blockEnd,
            variableStart: variableStart,
            variableEnd: variableEnd,
            commentStart: commentStart,
            commentEnd: commentEnd,
            autoEscape: autoEscape,
            trimBlocks: trimBlocks,
            leftStripBlocks: leftStripBlocks,
            finalize: _getFinalizer(finalize),
            optimize: optimize,
            undefined: undefined,
            extensions: extensions,
            filters: Map.of(defaultFilters)..addAll(filters),
            tests: Map.of(defaultTests)..addAll(tests),
            globals: Map.of(defaultContext)..addAll(globals),
          );
    _shared[list] = env;
    return Parser(env, source).parse();
  }

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

  void _setContext(StringBuffer buffer, Context context) {
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
    _setContext(buffer, context);
    body.accept(buffer, context);
  }

  String renderMap([Map<String, Object> data]) {
    final buffer = StringBuffer();
    final context = Context(data: data, env: env);
    _setContext(buffer, context);
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
