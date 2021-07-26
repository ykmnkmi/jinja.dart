import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show Random;

import 'package:quiver/core.dart';
import 'package:jinja/jinja.dart';

import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'lexer.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'optimizer.dart';
import 'parser.dart';
import 'renderer.dart';
import 'runtime.dart';
import 'utils.dart';
import 'visitor.dart';

typedef Finalizer = Object? Function(Object? value);

typedef ContextFinalizer = Object? Function(Context context, Object? value);

typedef EnvironmentFinalizer = Object? Function(
    Environment environment, Object? value);

typedef FieldGetter = Object? Function(Object? object, String field);

typedef UndefinedFactory = Undefined Function(
    {String? hint, Object? object, String? name});

late final Expando<Lexer> lexerCache = Expando('lexerCache');

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
///
/// Modifications on environments after the first template was loaded
/// will lead to surprising effects and undefined behavior.
class Environment {
  /// If `loader` is not `null`, templates will be loaded
  Environment({
    this.commentStart = defaults.commentStart,
    this.commentEnd = defaults.commentEnd,
    this.variableStart = defaults.variableStart,
    this.variableEnd = defaults.variableEnd,
    this.blockStart = defaults.blockStart,
    this.blockEnd = defaults.blockEnd,
    this.lineCommentPrefix = defaults.lineCommentPrefix,
    this.lineStatementPrefix = defaults.lineStatementPrefix,
    this.leftStripBlocks = defaults.lStripBlocks,
    this.trimBlocks = defaults.trimBlocks,
    this.newLine = defaults.newLine,
    this.keepTrailingNewLine = defaults.keepTrailingNewLine,
    this.optimized = true,
    this.undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    this.autoEscape = false,
    this.loader,
    this.autoReload = true,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    Map<String, Template>? templates,
    List<NodeVisitor>? modifiers,
    Random? random,
    this.fieldGetter = defaults.fieldGetter,
  })  : assert(finalize is Finalizer ||
            finalize is ContextFinalizer ||
            finalize is EnvironmentFinalizer),
        finalize = finalize is EnvironmentFinalizer
            ? ((context, value) => finalize(context.environment, value))
            : finalize is ContextFinalizer
                ? finalize
                : ((context, value) => finalize(value)),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        environmentFilters = HashSet<String>.of(defaults.environmentFilters),
        contextFilters = HashSet<String>.of(defaults.contextFilters),
        tests = HashMap<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
        modifiers = List<NodeVisitor>.of(defaults.modifiers),
        random = random ?? Random() {
    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (environmentFilters != null) {
      this.environmentFilters.addAll(environmentFilters);
    }

    if (contextFilters != null) {
      this.contextFilters.addAll(contextFilters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
    }

    if (templates != null) {
      this.templates.addAll(templates);
    }

    if (modifiers != null) {
      this.modifiers.addAll(modifiers);
    }
  }

  final String commentStart;

  final String commentEnd;

  final String variableStart;

  final String variableEnd;

  final String blockStart;

  final String blockEnd;

  final String? lineCommentPrefix;

  final String? lineStatementPrefix;

  final bool leftStripBlocks;

  final bool trimBlocks;

  final String newLine;

  final bool keepTrailingNewLine;

  final bool optimized;

  final UndefinedFactory undefined;

  final ContextFinalizer finalize;

  final bool autoEscape;

  final Loader? loader;

  final bool autoReload;

  final Map<String, Object?> globals;

  final Map<String, Function> filters;

  final Set<String> environmentFilters;

  final Set<String> contextFilters;

  final Map<String, Function> tests;

  final Map<String, Template> templates;

  final List<NodeVisitor> modifiers;

  final Random random;

  final FieldGetter fieldGetter;

  @override
  int get hashCode {
    return hashObjects(<Object?>[
      blockStart,
      blockEnd,
      variableStart,
      variableEnd,
      commentStart,
      commentEnd,
      lineStatementPrefix,
      lineCommentPrefix,
      trimBlocks,
      leftStripBlocks
    ]);
  }

  Lexer get lexer {
    return lexerCache[this] ??= Lexer(this);
  }

  @override
  bool operator ==(Object? other) {
    return other is Environment &&
        blockStart == other.blockStart &&
        blockEnd == other.blockEnd &&
        variableStart == other.variableStart &&
        variableEnd == other.variableEnd &&
        commentStart == other.commentStart &&
        commentEnd == other.commentEnd &&
        lineStatementPrefix == other.lineStatementPrefix &&
        lineCommentPrefix == other.lineCommentPrefix &&
        trimBlocks == other.trimBlocks &&
        leftStripBlocks == other.leftStripBlocks;
  }

  /// If [name] not found throws [TemplateRuntimeError].
  Object? callFilter(String name, Object? value,
      {List<Object?>? positional,
      Map<Symbol, Object?>? named,
      Context? context}) {
    Function filter;

    if (filters.containsKey(name)) {
      filter = filters[name]!;
    } else {
      throw TemplateRuntimeError('no filter named $name');
    }

    if (contextFilters.contains(name)) {
      if (context == null) {
        throw TemplateRuntimeError(
            'attempted to invoke context filter without context');
      }

      positional ??= <Object?>[];
      positional.insert(0, context);
      positional.insert(1, value);
    } else if (environmentFilters.contains(name)) {
      positional ??= <Object?>[];
      positional.insert(0, this);
      positional.insert(1, value);
    } else {
      positional ??= <Object?>[];
      positional.insert(0, value);
    }

    return Function.apply(filter, positional, named);
  }

  /// If [name] not found throws [TemplateRuntimeError].
  bool callTest(String name, Object? value,
      {List<Object?>? positional, Map<Symbol, Object?>? named}) {
    Function test;

    if (tests.containsKey(name)) {
      test = tests[name]!;
    } else {
      throw TemplateRuntimeError('no test named $name');
    }

    positional ??= <Object?>[];
    positional.insert(0, value);
    return Function.apply(test, positional, named) as bool;
  }

  Environment copy({
    String? commentStart,
    String? commentEnd,
    String? variableStart,
    String? variableEnd,
    String? blockStart,
    String? blockEnd,
    String? lineCommentPrefix,
    String? lineStatementPrefix,
    bool? leftStripBlocks,
    bool? trimBlocks,
    String? newLine,
    bool? keepTrailingNewLine,
    bool? optimized,
    UndefinedFactory? undefined,
    Function? finalize,
    bool? autoEscape,
    Loader? loader,
    bool? autoReload,
    Map<String, dynamic>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    List<NodeVisitor>? modifiers,
    Random? random,
    FieldGetter? fieldGetter,
  }) {
    return Environment(
      commentStart: commentStart ?? this.commentStart,
      commentEnd: commentEnd ?? this.commentEnd,
      variableStart: variableStart ?? this.variableStart,
      variableEnd: variableEnd ?? this.variableEnd,
      blockStart: blockStart ?? this.blockStart,
      blockEnd: blockEnd ?? this.blockEnd,
      lineCommentPrefix: lineCommentPrefix ?? this.lineCommentPrefix,
      lineStatementPrefix: lineStatementPrefix ?? this.lineStatementPrefix,
      leftStripBlocks: leftStripBlocks ?? this.leftStripBlocks,
      trimBlocks: trimBlocks ?? this.trimBlocks,
      newLine: newLine ?? this.newLine,
      keepTrailingNewLine: keepTrailingNewLine ?? this.keepTrailingNewLine,
      optimized: optimized ?? this.optimized,
      undefined: undefined ?? this.undefined,
      finalize: finalize ?? this.finalize,
      autoEscape: autoEscape ?? this.autoEscape,
      loader: loader ?? this.loader,
      autoReload: autoReload ?? this.autoReload,
      globals: globals ?? this.globals,
      filters: filters ?? this.filters,
      environmentFilters: environmentFilters ?? this.environmentFilters,
      contextFilters: contextFilters ?? this.contextFilters,
      tests: tests ?? this.tests,
      modifiers: modifiers ?? this.modifiers,
      random: random ?? this.random,
      fieldGetter: fieldGetter ?? this.fieldGetter,
    );
  }

  /// If `path` is not `null` template stored in environment cache.
  Template fromString(String source, {String? path}) {
    final template = Parser(this, path: path).parse(source);

    for (final modifier in modifiers) {
      for (final node in template.nodes) {
        modifier(node);
      }
    }

    if (optimized) {
      template.accept(const Optimizer(), Context(this));
    }

    return template;
  }

  Object? getAttribute(Object? object, String field) {
    try {
      return fieldGetter(object, field);
    } on NoSuchMethodError {
      try {
        return (object as dynamic)[field];
      } on NoSuchMethodError {
        return undefined(object: object, name: field);
      }
    }
  }

  Object? getItem(Object object, Object? key) {
    // TODO: update slices
    if (key is Indices) {
      if (object is List<Object?>) {
        return slice(object, key);
      }

      if (object is String) {
        return sliceString(object, key);
      }

      if (object is Iterable<Object?>) {
        return slice(object.toList(), key);
      }
    }

    if (key is int && key < 0) {
      key = key + ((object as dynamic).length as int);
    }

    try {
      return (object as dynamic)[key];
    } on NoSuchMethodError {
      if (key is String) {
        try {
          return fieldGetter(object, key);
        } on NoSuchMethodError {
          // do nothing
        }
      }

      return undefined(object: object, name: '$key');
    }
  }

  /// If [template] not found throws `Exception`.
  ///
  /// Throws [TypeError] if [template] is not a [String] or [Undefined].
  Template getTemplate(Object? template) {
    if (template is Undefined) {
      template.fail();
    }

    if (template is String) {
      if (autoReload && templates.containsKey(template)) {
        return templates[template] = loadTemplate(template);
      }

      return templates[template] ??= loadTemplate(template);
    }

    throw TypeError();
  }

  List<String> listTemplates() {
    assert(loader != null, 'no loader configured');
    return loader!.listTemplates();
  }

  List<Token> lex(String source) {
    // TODO: catch error
    return lexer.tokenize(source);
  }

  Template loadTemplate(String template) {
    assert(loader != null, 'no loader for this environment specified');
    return templates[template] = loader!.load(this, template);
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
  factory Template(
    String source, {
    String? path,
    Environment? parent,
    String blockStart = defaults.blockStart,
    String blockEnd = defaults.blockEnd,
    String variableStatr = defaults.variableStart,
    String variableEnd = defaults.variableEnd,
    String commentStart = defaults.commentStart,
    String commentEnd = defaults.commentEnd,
    String? lineCommentPrefix = defaults.lineCommentPrefix,
    String? lineStatementPrefix = defaults.lineStatementPrefix,
    bool trimBlocks = defaults.trimBlocks,
    bool leftStripBlocks = defaults.lStripBlocks,
    String newLine = defaults.newLine,
    bool keepTrailingNewLine = defaults.keepTrailingNewLine,
    bool optimized = true,
    UndefinedFactory undefined = defaults.undefined,
    Function finalize = defaults.finalize,
    bool autoEscape = false,
    Map<String, Object>? globals,
    Map<String, Function>? filters,
    Set<String>? environmentFilters,
    Set<String>? contextFilters,
    Map<String, Function>? tests,
    List<NodeVisitor>? modifiers,
    Random? random,
    FieldGetter fieldGetter = defaults.fieldGetter,
  }) {
    Environment environment;

    if (parent != null) {
      // TODO: update copying
      environment = parent.copy(
        commentStart: commentStart,
        commentEnd: commentEnd,
        variableStart: variableStatr,
        variableEnd: variableEnd,
        blockStart: blockStart,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        leftStripBlocks: leftStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        autoReload: false,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        contextFilters: contextFilters,
        tests: tests,
        modifiers: modifiers,
        random: random,
        fieldGetter: fieldGetter,
      );
    } else {
      environment = Environment(
        commentStart: commentStart,
        commentEnd: commentEnd,
        variableStart: variableStatr,
        variableEnd: variableEnd,
        blockStart: blockStart,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        leftStripBlocks: leftStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
        optimized: optimized,
        undefined: undefined,
        finalize: finalize,
        autoEscape: autoEscape,
        autoReload: false,
        globals: globals,
        filters: filters,
        environmentFilters: environmentFilters,
        contextFilters: contextFilters,
        tests: tests,
        modifiers: modifiers,
        random: random,
        fieldGetter: fieldGetter,
      );
    }

    return environment.fromString(source, path: path);
  }

  Template.parsed(this.environment, this.nodes,
      {this.blocks = const <Block>[], this.hasSelf = false, this.path});

  final Environment environment;

  final List<Node> nodes;

  final List<Block> blocks;

  final bool hasSelf;

  final String? path;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitTemplate(this, context);
  }

  String render([Map<String, Object?>? data]) {
    final buffer = StringBuffer();
    final context = RenderContext(environment, buffer, data: data);
    accept(const StringSinkRenderer(), context);
    return buffer.toString();
  }

  @override
  String toString() {
    if (path == null) {
      return 'Template()';
    }

    return 'Template($path)';
  }
}
