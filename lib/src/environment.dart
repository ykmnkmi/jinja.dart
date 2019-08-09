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
  Environment({
    this.blockStart = '{%',
    this.blockEnd = '%}',
    this.variableStart = '{{',
    this.variableEnd = '}}',
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.trimBlocks = false,
    this.leftStripBlocks = false,
    this.finalize = _defaultFinalizer,
    this.loader,
    this.optimize = true,
    this.undefined = const Undefined(),
    Map<String, ParserCallback> extensions = const <String, ParserCallback>{},
    Map<String, dynamic> globals = const <String, dynamic>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
  })  : extensions = Map.of(defaultExtensions)..addAll(extensions),
        globalContext = Map.of(defaultContext)..addAll(globals),
        filters = Map.of(defaultFilters)..addAll(filters),
        tests = Map.of(defaultTests)..addAll(tests),
        templates = <String, Template>{},
        keywords = List.of(defaultKeywords) {
    if (loader != null) loader.load(this);
  }

  /// The string marking the beginning of a statement.
  final String blockStart;

  /// The string marking the end of a statement.
  final String blockEnd;

  /// The string marking the beginning of a variable statement.
  final String variableStart;

  /// The string marking the end of a variable statement.
  final String variableEnd;

  /// The string marking the beginning of a comment.
  final String commentStart;

  /// The string marking the end of a comment.
  final String commentEnd;

  /// If this is set to `true` the first newline after a block is removed.
  final bool trimBlocks;

  /// If this is set to `true` leading spaces and tabs are stripped
  /// from the start of a line to a block
  final bool leftStripBlocks;

  /// A callable that can be used to process the result of a variable
  /// expression before it is output. For example one can convert `null`
  /// implicitly into an empty string here.
  final Finalizer finalize;

  /// The template loader for this environment
  final Loader loader;

  /// Undefined or a subclass of it that is used to represent undefined
  /// values in the template.
  final Undefined undefined;

  /// Map of Jinja global variables and functions to use.
  final Map<String, dynamic> globalContext;

  /// Map of Jinja filters to use.
  final Map<String, Function> filters;

  /// Map of Jinja tests to use.
  final Map<String, Function> tests;

  final bool optimize;
  final Map<String, ParserCallback> extensions;
  final List<String> keywords;
  final Map<String, Template> templates;

  /// Load a template from a string. This parses the source given and
  /// returns a Template object.
  ///
  /// If `path` key is not `null` template stored in environment cache.
  Template fromSource(String source, {String path}) {
    final template = Parser(this, source, path: path).parse();
    if (path != null) templates[path] = template;
    return template;
  }

  /// Get template by `path`.
  ///
  /// If path not found throws `Exception`.
  Template getTemplate(String path) {
    if (!templates.containsKey(path)) {
      throw Exception('Template not found: $path');
    }

    return templates[path];
  }

  /// Call filter by `name`.
  ///
  /// If filter not found throws `Exception`.
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

  /// Call test by `name`.
  ///
  /// If test not found throws `Exception`.
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
