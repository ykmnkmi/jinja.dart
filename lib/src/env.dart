import 'context.dart';
import 'defaults.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'parser.dart';
import 'runtime.dart';

typedef dynamic Finalizer(dynamic value);
dynamic _defaultFinalizer(dynamic value) => value ?? const Undefined();

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
///
/// Modifications on environments after the first template was loaded
/// will lead to surprising effects and undefined behavior.
class Environment {
  /// Environment constructor. Load all templates from [loader] to cache.
  Environment({
    this.stmtOpen = '\{%',
    this.stmtClose = '%\}',
    this.varOpen = '\{\{',
    this.varClose = '\}\}',
    this.commentOpen = '\{#',
    this.commentClose = '#\}',
    this.undefined = const Undefined(),
    this.finalize = _defaultFinalizer,
    this.loader,
    this.autoReload = true,
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, dynamic> globals = const <String, dynamic>{},
  })  : _templates = <String, Template>{},
        filters = Map<String, Function>.of(defaultFilters)..addAll(filters),
        tests = Map<String, Function>.of(defaultTests)..addAll(tests),
        globals = Map<String, dynamic>.of(defaultNameSpace)..addAll(globals) {
    if (loader != null) loader.load(this);
  }

  /// The string marking the beginning of a statement.
  final String stmtOpen;

  /// The string marking the end of a statement.
  final String stmtClose;

  /// The string marking the beginning of a variable statement.
  final String varOpen;

  /// The string marking the end of a variable statement.
  final String varClose;

  /// The string marking the beginning of a comment.
  final String commentOpen;

  /// The string marking the end of a comment.
  final String commentClose;

  /// Map of Jinja filters to use.
  final Map<String, Function> filters;

  /// Map of Jinja tests to use.
  final Map<String, Function> tests;

  /// Map of Jinja global variables and functions to use.
  final Map<String, dynamic> globals;

  /// Undefined or a subclass of it that is used to represent undefined
  /// values in the template.
  final Undefined undefined;

  /// A callable that can be used to process the result of a variable
  /// expression before it is output. For example one can convert `null`
  /// implicitly into an empty string here.
  final Finalizer finalize;

  /// The template loader for this environment.
  final Loader loader;

  /// Some loaders load templates from location where the template
  /// sources may change (ie: file system or database).  If
  /// [autoReload] is set to `true` (default) every time
  /// a template source changed loader reload template.
  /// For higher performance it's possible to disable that.
  final bool autoReload;

  final Map<String, Template> _templates;

  /// Load a template from a string. This parses the source given and
  /// returns a Template object.
  ///
  /// If `store` key is `true` template stored on env cache.
  Template fromSource(String source, {String path, bool store = false}) {
    final template = Template(this, source, path: path);
    if (store) if (path != null)
      _templates[path] = template;
    else
      throw ArgumentError.notNull('path');
    return template;
  }

  /// Get template by `path`.
  ///
  /// If path not found throws [Exception].
  Template getTemplate(String path) {
    if (!_templates.containsKey(path))
      throw Exception('Template not found: $path');
    return _templates[path];
  }

  /// Call template by `path` with optional [data].
  ///
  /// If path not found throws [Exception].
  String callTemplate(String path, [Map<String, dynamic> data]) {
    if (!_templates.containsKey(path))
      throw Exception('Template not found: $path');
    return _templates[path].render(data);
  }

  /// Call template by `path` with optional [Context].
  ///
  /// If `path` not found throws [Exception].
  String callTemplateWithContext(String path, [Context context]) {
    if (!_templates.containsKey(path))
      throw Exception('Template not found: $path');
    return _templates[path].renderContext(context);
  }

  /// Get filter by `name`.
  ///
  /// If `name` not found throws [Exception].
  Function getFilter(String name) {
    if (!filters.containsKey(name)) throw Exception('Filter not found: $name');
    return filters[name];
  }

  /// Call filter by `path`.
  ///
  /// If path not found throws [Exception].
  callFilter(String name,
      [List args = const [],
      Map<Symbol, dynamic> kwargs = const <Symbol, dynamic>{}]) {
    if (!filters.containsKey(name)) throw Exception('Filter not found: $name');
    return Function.apply(filters[name], args, kwargs);
  }

  /// Get test by [name].
  ///
  /// If `name` not found throws [Exception].
  Function getTest(String name) {
    if (!tests.containsKey(name)) throw Exception('Test not found: $name');
    return tests[name];
  }

  /// Call test by `path`.
  ///
  /// If `name` not found throws [Exception].
  callTest(String name,
      [List args = const [],
      Map<Symbol, dynamic> kwargs = const <Symbol, dynamic>{}]) {
    if (!tests.containsKey(name)) throw Exception('Test not found: $name');
    return Function.apply(tests[name], args, kwargs);
  }

  @override
  String toString() => 'Env($autoReload, $loader)';
}

/// The central template object. This class represents a compiled template
/// and is used to evaluate it.
class Template {
  Template(this.env, String source, {String path})
      : path = path,
        body = Parser(env).parse(source, path: path);

  final Environment env;
  final String path;
  final Node body;

  /// If no arguments are given the context will be empty.
  /// This will return the rendered template as unicode string.
  String render([Map<String, dynamic> context]) =>
      body.render(Context(env, data: context ?? const <String, dynamic>{}));

  /// If no arguments are given the context will be empty.
  /// This will return the rendered template as unicode string.
  String renderContext(Context context) => body.render(context);

  @override
  String toString() => 'Template($body${path != null ? ', ' + path : ''})';
}
