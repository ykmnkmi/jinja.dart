import 'dart:math' show Random;

import 'package:path/path.dart' as p;

import 'defaults.dart';
import 'filters.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'parser.dart';
import 'runtime.dart';

typedef FieldGetter = Object? Function(Object? object, String field);
typedef ItemGetter = Object? Function(Object? object, Object? key);

Object? defaultFieldGetter(Object? object, String field) {
  return null;
}

Object? defaultItemGetter(Object? object, Object? key) {
  if (object is List) {
    return object.asMap()[key];
  }

  if (object is Map) {
    return object[key];
  }

  return null;
}

typedef Finalizer = Object Function(Object? value);

Object defaultFinalizer(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value;
  }

  return repr(value);
}

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
///
/// Modifications on environments after the first template was loaded
/// will lead to surprising effects and undefined behavior.
class Environment {
  /// If `loader` is not `null`, templates will be loaded
  Environment(
      {this.blockStart = '{%',
      this.blockEnd = '%}',
      this.variableStart = '{{',
      this.variableEnd = '}}',
      this.commentStart = '{#',
      this.commentEnd = '#}',
      this.trimBlocks = false,
      this.leftStripBlocks = false,
      this.keepTrailingNewLine = false,
      this.optimize = true,
      this.undefined = const Undefined(),
      this.finalize = defaultFinalizer,
      Random? random,
      this.autoEscape = false,
      Loader? loader,
      Map<String, Function> filters = const <String, Function>{},
      Map<String, Function> tests = const <String, Function>{},
      Map<String, dynamic> globals = const <String, dynamic>{},
      this.getField = defaultFieldGetter,
      this.getItem = defaultItemGetter})
      : random = random ?? Random(),
        filters = Map<String, Function>.of(defaultFilters)..addAll(filters),
        tests = Map<String, Function>.of(defaultTests)..addAll(tests),
        globals = Map<String, dynamic>.of(defaultContext)..addAll(globals),
        templates = <String, Template>{} {
    if (loader != null) {
      loader.load(this);
    }
  }

  final String blockStart;
  final String blockEnd;
  final String variableStart;
  final String variableEnd;
  final String commentStart;
  final String commentEnd;
  final bool trimBlocks;
  final bool leftStripBlocks;
  final bool keepTrailingNewLine;
  final bool optimize;
  final Undefined undefined;
  final Finalizer finalize;
  final Random random;
  final bool autoEscape;
  final Map<String, Function> filters;
  final Map<String, Function> tests;
  final Map<String, dynamic> globals;

  final FieldGetter getField;
  final ItemGetter getItem;

  final Map<String, Template> templates;

  /// If `path` is not `null` template stored in environment cache.
  Template fromString(String source, {String? path}) {
    final template = Parser(this, source, path: path).parse();

    if (path != null) {
      templates[path] = template;
    }

    return template;
  }

  /// If [path] not found throws `Exception`.
  ///
  /// `path/to/template`
  Template getTemplate(String path) {
    final normalizedPath = p.normalize(path);

    if (templates.containsKey(normalizedPath)) {
      return templates[normalizedPath]!;
    }

    throw ArgumentError('template not found: $path');
  }

  /// If [name] not found throws [Exception].
  Object? callFilter(Context context, String name,
      {List<Object?> positional = const [],
      Map<Symbol, Object?> named = const {}}) {
    if (filters.containsKey(name) && filters[name] != null) {
      final filter = filters[name]!;

      switch (getFilterType(filter)) {
        case FilterType.context:
          final args = <Object?>[context];
          args.addAll(positional);
          return Function.apply(filter, args, named);
        case FilterType.environment:
          final args = <Object?>[context.environment];
          args.addAll(positional);
          return Function.apply(filter, args, named);
        default:
          return Function.apply(filter, positional, named);
      }
    }

    throw ArgumentError('filter not found: $name');
  }

  /// If [name] not found throws [Exception].
  bool callTest(String name,
      {List<Object?> positional = const [],
      Map<Symbol, Object?> named = const {}}) {
    if (tests.containsKey(name)) {
      return Function.apply(tests[name]!, positional, named) as bool;
    }

    throw ArgumentError('test not found: $name');
  }
}

/// The central `Template` object. This class represents a compiled template
/// and is used to evaluate it.
///
/// Normally the template is generated from `Environment` but
/// it also has a constructor that makes it possible to create a template
/// instance directly using the constructor. It takes the same arguments as
/// the environment constructor but it's not possible to specify a loader.
class Template extends Node {
  factory Template(String source,
      {String blockStart = '{%',
      String blockEnd = '%}',
      String variableStart = '{{',
      String variableEnd = '}}',
      String commentStart = '{#',
      String commentEnd = '#}',
      bool trimBlocks = false,
      bool leftStripBlocks = false,
      bool keepTrailingNewLine = false,
      bool optimize = true,
      Undefined undefined = const Undefined(),
      Finalizer finalize = defaultFinalizer,
      Random? random,
      bool autoEscape = false,
      Map<String, Function> filters = const <String, Function>{},
      Map<String, Function> tests = const <String, Function>{},
      Map<String, Object?> globals = const <String, Object?>{},
      FieldGetter getField = defaultFieldGetter,
      ItemGetter getItem = defaultItemGetter}) {
    final env = Environment(
      blockStart: blockStart,
      blockEnd: blockEnd,
      variableStart: variableStart,
      variableEnd: variableEnd,
      commentStart: commentStart,
      commentEnd: commentEnd,
      trimBlocks: trimBlocks,
      leftStripBlocks: leftStripBlocks,
      keepTrailingNewLine: keepTrailingNewLine,
      optimize: optimize,
      undefined: undefined,
      finalize: finalize,
      random: random,
      autoEscape: autoEscape,
      filters: Map<String, Function>.of(defaultFilters)..addAll(filters),
      tests: Map<String, Function>.of(defaultTests)..addAll(tests),
      globals: Map<String, Object?>.of(defaultContext)..addAll(globals),
      getField: getField,
      getItem: getItem,
    );

    return Parser(env, source).parse();
  }

  Template.parsed(this.environment, this.body, [this.path])
      : blocks = <String, BlockStatement>{} {
    _render = RenderWrapper(([Map<String, Object?>? data]) => renderMap(data));
  }

  final Environment environment;
  final Node body;
  final String? path;

  final Map<String, BlockStatement> blocks;

  late dynamic _render;

  dynamic get render {
    return _render;
  }

  void _addBlocks(Context context, StringSink outSink) {
    final self = NameSpace();

    for (final blockEntry in blocks.entries) {
      self[blockEntry.key] = () {
        blockEntry.value.accept(outSink, context);
      };
    }

    context.contexts.first['self'] = self;
  }

  @override
  void accept(StringSink outSink, Context context) {
    _addBlocks(context, outSink);
    body.accept(outSink, context);
  }

  String renderMap([Map<String, dynamic>? data]) {
    final buffer = StringBuffer();
    final context = Context(environment, data ?? <String, dynamic>{});
    _addBlocks(context, buffer);
    body.accept(buffer, context);
    return buffer.toString();
  }

  @override
  String toString() {
    if (path == null) {
      return 'Template($body)';
    }

    return 'Template($path, $body)';
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer();

    if (path != null) {
      buffer
        ..write(' ' * level)
        ..write('# template: ')
        ..writeln(repr(path));
    }

    buffer.write(body.toDebugString(level));
    return buffer.toString();
  }
}

class RenderWrapper {
  RenderWrapper(this.renderMap);

  final String Function([Map<String, Object?>? data]) renderMap;

  String call() {
    return renderMap();
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final map = <String, Object?>{};

      for (final symbol in invocation.namedArguments.keys) {
        map[getSymbolName(symbol)] = invocation.namedArguments[symbol];
      }

      return renderMap(map);
    }

    return super.noSuchMethod(invocation);
  }
}
