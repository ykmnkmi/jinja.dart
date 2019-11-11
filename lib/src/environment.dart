import 'package:meta/meta.dart';

import 'defaults.dart';
import 'exceptions.dart';
import 'ext.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'parser.dart';
import 'runtime.dart';

typedef FieldGetter = Object Function(Object object, String field);
Object defaultFieldGetter(Object object, String field) {
  throw TemplateRuntimeError('getField not implemented');
}

typedef ItemGetter = Object Function(Object object, Object key);
Object defaultItemGetter(dynamic object, Object key) {
  try {
    return object[key];
  } catch (e) {
    throw TemplateRuntimeError(e.toString());
  }
}

typedef Finalizer = Object Function(Object value);
Object defaultFinalizer(Object value) {
  value = value ?? '';
  if (value is String) return value;
  return repr(value, false);
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
    Finalizer finalize = defaultFinalizer,
    FieldGetter getField = defaultFieldGetter,
    ItemGetter getItem = defaultItemGetter,
    Undefined undefined = const Undefined(),
    Loader loader,
    bool optimize = true,
    Iterable<Extension> extensions = const <Extension>[],
    Map<String, Function> envFilters = const <String, Function>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, Object> globals = const <String, Object>{},
  }) {
    Environment env = Environment._(
      blockStart: blockStart,
      blockEnd: blockEnd,
      variableStart: variableStart,
      variableEnd: variableEnd,
      commentStart: commentStart,
      commentEnd: commentEnd,
      autoEscape: autoEscape,
      trimBlocks: trimBlocks,
      leftStripBlocks: leftStripBlocks,
      finalize: finalize,
      getField: getField,
      getItem: getItem,
      undefined: undefined,
      optimize: optimize,
      extensions: extensions,
      envFilters: Map<String, Function>.of(defaultEnvFilters)
        ..addAll(envFilters),
      filters: Map<String, Function>.of(defaultFilters)..addAll(filters),
      tests: Map<String, Function>.of(defaultTests)..addAll(tests),
      globals: Map<String, Object>.of(defaultContext)..addAll(globals),
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
    this.getField,
    this.getItem,
    this.undefined,
    this.optimize,
    this.shared,
    this.extensions = const <Extension>[],
    this.envFilters = const <String, Function>{},
    this.filters = const <String, Function>{},
    this.tests = const <String, Function>{},
    this.globals = const <String, Object>{},
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
  final FieldGetter getField;
  final ItemGetter getItem;
  final Undefined undefined;
  final bool optimize;
  final bool shared;
  final Iterable<Extension> extensions;
  final Map<String, Function> envFilters;
  final Map<String, Function> filters;
  final Map<String, Function> tests;
  final Map<String, Object> globals;

  final Map<String, Template> templates = <String, Template>{};

  /// If `path` is not `null` template stored in environment cache.
  Template fromString(String source, {String path}) {
    Template template = Parser(this, source, path: path).parse();
    if (path != null) templates[path] = template;
    return template;
  }

  /// If [path] not found throws `Exception`.
  Template getTemplate(String path) {
    if (!templates.containsKey(path)) {
      throw Exception('template not found: $path');
    }

    return templates[path];
  }

  /// If [name] not found throws [Exception].
  Object callFilter(
    String name, {
    List<Object> args = const <Object>[],
    Map<Symbol, Object> kwargs = const <Symbol, Object>{},
  }) {
    if (envFilters.containsKey(name) && envFilters[name] != null) {
      return Function.apply(envFilters[name], <Object>[this, ...args], kwargs);
    }

    if (filters.containsKey(name) && filters[name] != null) {
      return Function.apply(filters[name], args, kwargs);
    }

    throw Exception('filter not found: $name');
  }

  /// If [name] not found throws [Exception].
  bool callTest(
    String name, {
    List<Object> args = const <Object>[],
    Map<Symbol, Object> kwargs = const <Symbol, Object>{},
  }) {
    if (!tests.containsKey(name)) {
      throw Exception('test not found: $name');
    }

    // ignore: return_of_invalid_type
    return Function.apply(tests[name], args, kwargs);
  }
}

typedef ContextModifier = void Function(Context context);

/// The central `Template` object. This class represents a compiled template
/// and is used to evaluate it.
///
/// Normally the template is generated from `Environment` but
/// it also has a constructor that makes it possible to create a template
/// instance directly using the constructor.  It takes the same arguments as
/// the environment constructor but it's not possible to specify a loader.
class Template extends Node {
  static final Map<List<Object>, Environment> _shared =
      <List<Object>, Environment>{};

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
    Finalizer finalize = defaultFinalizer,
    FieldGetter getField = defaultFieldGetter,
    ItemGetter getItem = defaultItemGetter,
    bool optimize = true,
    Undefined undefined = const Undefined(),
    Iterable<Extension> extensions = const <Extension>[],
    Map<String, Function> envFilters = const <String, Function>{},
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, Object> globals = const <String, Object>{},
    Loader loader,
  }) {
    List<Object> list = <Object>[
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
      getField,
      getItem,
      undefined,
      optimize,
      extensions,
      envFilters,
      filters,
      tests,
      globals,
      loader,
    ];

    Environment env = _shared.containsKey(list)
        ? _shared[list]
        : Environment(
            blockStart: blockStart,
            blockEnd: blockEnd,
            variableStart: variableStart,
            variableEnd: variableEnd,
            commentStart: commentStart,
            commentEnd: commentEnd,
            autoEscape: autoEscape,
            trimBlocks: trimBlocks,
            leftStripBlocks: leftStripBlocks,
            finalize: finalize,
            getField: getField,
            getItem: getItem,
            undefined: undefined,
            optimize: optimize,
            extensions: extensions,
            envFilters: envFilters,
            filters: filters,
            tests: tests,
            globals: globals,
            loader: loader,
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
    NameSpace self = NameSpace();

    for (MapEntry<String, BlockStatement> blockEntry in blocks.entries) {
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
    StringBuffer buffer = StringBuffer();
    Context context = Context(data: data, env: env);
    _setContext(buffer, context);
    body.accept(buffer, context);
    return buffer.toString();
  }

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer();

    if (path != null) {
      buffer.write(' ' * level);
      buffer.writeln('# template: ${repr(path)}');
    }

    buffer.write(body.toDebugString(level));
    return buffer.toString();
  }

  @override
  String toString() => 'Template($path, $body)';
}

// TODO: remove deprecated
// ignore: deprecated_extends_function
class RenderWrapper extends Function {
  RenderWrapper(this.function);

  final Function function;

  Object call() => function();

  @override
  Object noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.namedArguments.map<String, Object>(
          (Symbol key, Object value) =>
              MapEntry<String, Object>(getSymbolName(key), value)));
    }

    return super.noSuchMethod(invocation);
  }
}
