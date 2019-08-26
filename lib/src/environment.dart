import 'dart:async';

import 'package:meta/meta.dart';

import 'defaults.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'parser.dart';
import 'undefined.dart';

typedef dynamic Finalizer(dynamic value);
dynamic _defaultFinalizer(dynamic value) => value ?? '';

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
  Environment({
    this.blockStart = '{%',
    this.blockEnd = '%}',
    this.variableStart = '{{',
    this.variableEnd = '}}',
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.autoEscape = false,
    this.trimBlocks = false,
    this.leftStripBlocks = false,
    Finalizer finalize = _defaultFinalizer,
    this.loader,
    this.optimize = true,
    this.undefined = const Undefined(),
    this.extensions = const <String, ParserCallback>{},
    Map<String, Object> globals = const <String, Object>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
  })  : finalize = ((value) {
          value = finalize(value);
          if (value is! String) return repr(value, false);
          return value;
        }),
        globals = Map.of(defaultContext)..addAll(globals),
        filters = Map.of(defaultFilters)..addAll(filters),
        tests = Map.of(defaultTests)..addAll(tests),
        templates = <String, Template>{} {
    if (loader != null) loader.load(this);
  }

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
  final Map<String, Object> globals;
  final Map<String, Function> filters;
  final Map<String, Function> tests;
  final bool optimize;
  final Loader loader;
  final Map<String, ParserCallback> extensions;
  final Map<String, Template> templates;

  Future<void> compileTemplats() async {}

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
