import 'package:meta/meta.dart';

import 'defaults.dart';
import 'exceptions.dart';
import 'ext.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'parser.dart';
import 'runtime.dart';

typedef FieldGetter = Object Function(Object object, String field);
typedef ItemGetter = Object Function(Object object, Object key);

Object defaultFieldGetter(Object object, String field) {
  throw TemplateRuntimeError('getField not implemented');
}

Object defaultItemGetter(dynamic object, Object key) {
  try {
    return object[key];
  } catch (e) {
    throw TemplateRuntimeError('$e');
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
    bool trimBlocks = false,
    bool leftStripBlocks = false,
    bool keepTrailingNewLine = false,
    Set<Extension> extensions = const <Extension>{},
    bool optimize = true,
    Undefined undefined = const Undefined(),
    Finalizer finalize = defaultFinalizer,
    bool autoEscape = false,
    Loader loader,
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> envFilters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, Object> globals = const <String, Object>{},
    FieldGetter getField = defaultFieldGetter,
    ItemGetter getItem = defaultItemGetter,
  }) {
    Environment env = Environment._(
      blockStart: blockStart,
      blockEnd: blockEnd,
      variableStart: variableStart,
      variableEnd: variableEnd,
      commentStart: commentStart,
      commentEnd: commentEnd,
      trimBlocks: trimBlocks,
      leftStripBlocks: leftStripBlocks,
      keepTrailingNewLine: keepTrailingNewLine,
      extensions: extensions,
      optimize: optimize,
      undefined: undefined,
      finalize: finalize,
      autoEscape: autoEscape,
      filters: Map<String, Function>.of(defaultFilters)..addAll(filters),
      envFilters: Map<String, Function>.of(defaultEnvFilters)..addAll(envFilters),
      tests: Map<String, Function>.of(defaultTests)..addAll(tests),
      globals: Map<String, Object>.of(defaultContext)..addAll(globals),
      getField: getField,
      getItem: getItem,
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
    this.trimBlocks,
    this.leftStripBlocks,
    this.keepTrailingNewLine,
    this.extensions = const <Extension>{},
    this.optimize,
    this.undefined,
    this.finalize,
    this.autoEscape,
    this.shared,
    this.filters = const <String, Function>{},
    this.envFilters = const <String, Function>{},
    this.tests = const <String, Function>{},
    this.globals = const <String, Object>{},
    this.getField,
    this.getItem,
  }) : templates = <String, Template>{};

  final String blockStart;
  final String blockEnd;
  final String variableStart;
  final String variableEnd;
  final String commentStart;
  final String commentEnd;
  final bool trimBlocks;
  final bool leftStripBlocks;
  final bool keepTrailingNewLine;
  final Set<Extension> extensions;
  final bool optimize;
  final Undefined undefined;
  final Finalizer finalize;
  final bool autoEscape;
  final bool shared;
  final Map<String, Function> filters;
  final Map<String, Function> envFilters;
  final Map<String, Function> tests;
  final Map<String, Object> globals;

  final FieldGetter getField;
  final ItemGetter getItem;

  final Map<String, Template> templates;

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
  Object callFilter(String name,
      {List<Object> args = const <Object>[], Map<Symbol, Object> kwargs = const <Symbol, Object>{}}) {
    if (envFilters.containsKey(name) && envFilters[name] != null) {
      return Function.apply(envFilters[name], <Object>[this, ...args], kwargs);
    }

    if (filters.containsKey(name) && filters[name] != null) {
      return Function.apply(filters[name], args, kwargs);
    }

    throw Exception('filter not found: $name');
  }

  /// If [name] not found throws [Exception].
  bool callTest(String name,
      {List<Object> args = const <Object>[], Map<Symbol, Object> kwargs = const <Symbol, Object>{}}) {
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
  static final Map<int, Environment> _shared = <int, Environment>{};

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
    bool keepTrailingNewLine = false,
    Set<Extension> extensions = const <Extension>{},
    bool optimize = true,
    Undefined undefined = const Undefined(),
    Finalizer finalize = defaultFinalizer,
    bool autoEscape = false,
    Loader loader,
    Map<String, Function> filters = const <String, Function>{},
    Map<String, Function> envFilters = const <String, Function>{},
    Map<String, Function> tests = const <String, Function>{},
    Map<String, Object> globals = const <String, Object>{},
    FieldGetter getField = defaultFieldGetter,
    ItemGetter getItem = defaultItemGetter,
  }) {
    Set<Object> config = <Object>{
      blockStart,
      blockEnd,
      variableStart,
      variableEnd,
      commentStart,
      commentEnd,
      trimBlocks,
      leftStripBlocks,
      keepTrailingNewLine,
      extensions,
      optimize,
      undefined,
      finalize,
      autoEscape,
      loader,
      filters,
      envFilters,
      tests,
      globals,
      getField,
      getItem,
    };

    Environment env = _shared.containsKey(config)
        ? _shared[config.hashCode]
        : Environment._(
            blockStart: blockStart,
            blockEnd: blockEnd,
            variableStart: variableStart,
            variableEnd: variableEnd,
            commentStart: commentStart,
            commentEnd: commentEnd,
            trimBlocks: trimBlocks,
            leftStripBlocks: leftStripBlocks,
            keepTrailingNewLine: keepTrailingNewLine,
            extensions: extensions,
            optimize: optimize,
            undefined: undefined,
            finalize: finalize,
            autoEscape: autoEscape,
            shared: true,
            filters: Map<String, Function>.of(defaultFilters)..addAll(filters),
            envFilters: Map<String, Function>.of(defaultEnvFilters)..addAll(envFilters),
            tests: Map<String, Function>.of(defaultTests)..addAll(tests),
            globals: Map<String, Object>.of(defaultContext)..addAll(globals),
            getField: getField,
            getItem: getItem,
          );

    _shared[config.hashCode] = env;
    if (loader != null) loader.load(env);
    return Parser(env, source).parse();
  }

  Template.parsed({@required this.body, @required this.env, this.path}) : blocks = <String, BlockStatement>{} {
    _renderWr = RenderWrapper(([Map<String, Object> data]) => render(data));
  }

  final Node body;
  final Environment env;
  final String path;

  final Map<String, BlockStatement> blocks;

  dynamic _renderWr;
  Function get renderWr => _renderWr as Function;

  void _addBlocks(StringBuffer buffer, Context context) {
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
    _addBlocks(buffer, context);
    body.accept(buffer, context);
  }

  String render([Map<String, Object> data]) {
    StringBuffer buffer = StringBuffer();
    Context context = Context(data: data, env: env);
    _addBlocks(buffer, context);
    body.accept(buffer, context);
    return buffer.toString();
  }

  @override
  String toString() => 'Template($path, $body)';

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer();

    if (path != null) {
      buffer.write(' ' * level);
      buffer.writeln('# template: ${repr(path)}');
    }

    buffer.write(body.toDebugString(level));
    return '$buffer';
  }
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
      return function(invocation.namedArguments
          .map<String, Object>((Symbol key, Object value) => MapEntry<String, Object>(getSymbolName(key), value)));
    }

    return super.noSuchMethod(invocation);
  }
}
