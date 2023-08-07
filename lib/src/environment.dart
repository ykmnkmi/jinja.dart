import 'dart:collection' show HashMap;
import 'dart:math' show Random;

import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/defaults.dart' as defaults;
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/lexer.dart';
import 'package:jinja/src/loaders.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:jinja/src/parser.dart';
import 'package:jinja/src/renderer.dart';
import 'package:jinja/src/utils.dart';
import 'package:meta/meta.dart';

/// {@template finalizer}
/// A [Function] that can be used to process the result of a variable
/// expression before it is output.
///
/// For example one can convert `null` implicitly into an empty string here.
/// {@endtemplate}
typedef Finalizer = Object Function(Object? value);

/// {@macro finalizer}
///
/// Takes [Context] as first argument.
typedef ContextFinalizer = Object Function(Context context, Object? value);

/// {@macro finalizer}
///
/// Takes [Environment] as first argument.
typedef EnvironmentFinalizer = Object Function(
    Environment environment, Object? value);

/// A [Function] that can be used to get object atribute.
///
/// Used by `object.attribute` expression.
typedef AttributeGetter = Object? Function(String attribute, Object? object);

/// A [Function] that can be used to get object item.
///
/// Used by `object['item']` expression.
typedef ItemGetter = Object? Function(Object key, Object? object);

/// Pass the [Context] as the first argument to the applied function when
/// called while rendering a template.
///
/// Can be used on functions, filters, and tests.
Function passContext(Function function) {
  PassArgument.types[function] = PassArgument.context;
  return function;
}

/// Pass the [Environment] as the first argument to the applied function when
/// called while rendering a template.
///
/// Can be used on functions, filters, and tests.
Function passEnvironment(Function function) {
  PassArgument.types[function] = PassArgument.environment;
  return function;
}

/// {@template environment}
/// The core component of Jinja 2 is the Environment.
/// {@endtemplate}
///
/// It contains important shared variables like configuration, filters, tests
/// and others.
///
/// Environment modifications can break templates that have been parsed or loaded.
class Environment {
  /// {@macro environment}
  Environment({
    this.commentStart = '{#',
    this.commentEnd = '#}',
    this.variableStart = '{{',
    this.variableEnd = '}}',
    this.blockStart = '{%',
    this.blockEnd = '%}',
    this.lineCommentPrefix,
    this.lineStatementPrefix,
    this.leftStripBlocks = false,
    this.trimBlocks = false,
    this.newLine = '\n',
    this.keepTrailingNewLine = false,
    this.optimize = true,
    Function finalize = defaults.finalize,
    this.loader,
    this.autoReload = true,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
    List<Node Function(Node)>? modifiers,
    Map<String, Template>? templates,
    Random? random,
    AttributeGetter? getAttribute,
    this.getItem = defaults.getItem,
  })  : finalize = wrapFinalizer(finalize),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        tests = HashMap<String, Function>.of(defaults.tests),
        modifiers = <Node Function(Node)>[],
        templates = HashMap<String, Template>(),
        random = random ?? Random(),
        getAttribute = wrapGetAttribute(getAttribute, getItem) {
    if (newLine != '\r' && newLine != '\n' && newLine != '\r\n') {
      // TODO(environment): update error
      throw ArgumentError.value(newLine);
    }

    if (globals case var globals?) {
      this.globals.addAll(globals);
    }

    if (filters case var filters?) {
      this.filters.addAll(filters);
    }

    if (tests case var tests?) {
      this.tests.addAll(tests);
    }

    if (modifiers case var modifiers?) {
      this.modifiers.addAll(modifiers);
    }

    if (templates case var templates?) {
      this.templates.addAll(templates);
    }
  }

  /// The string marking the beginning of a comment.
  final String commentStart;

  /// The string marking the end of a comment.
  final String commentEnd;

  /// The string marking the beginning of a print statement.
  final String variableStart;

  /// The string marking the end of a print statement.
  final String variableEnd;

  /// The string marking the beginning of a block.
  final String blockStart;

  /// The string marking the end of a block
  final String blockEnd;

  /// If given and a string, this will be used as prefix for line based
  /// comments.
  final String? lineCommentPrefix;

  /// If given and a string, this will be used as prefix for line based
  /// statements.
  final String? lineStatementPrefix;

  /// If this is set to `true` leading spaces and tabs are stripped
  /// from the start of a line to a block.
  final bool leftStripBlocks;

  /// If this is set to `true` the first newline after a block is
  /// removed (block, not variable tag!).
  final bool trimBlocks;

  /// The sequence that starts a newline.
  ///
  /// Must be one of `\r`, `\n` or `\r\n`.
  final String newLine;

  /// Preserve the trailing newline when rendering templates.
  /// The default is `false`, which causes a single newline,
  /// if present, to be stripped from the end of the template.
  final bool keepTrailingNewLine;

  /// Should the optimizer be enabled?
  final bool optimize;

  /// A Function that can be used to process the result of a variable
  /// expression before it is output.
  ///
  /// For example one can convert `null` (`none`) implicitly into an empty
  /// string here.
  final ContextFinalizer finalize;

  /// The template loader for this environment.
  final Loader? loader;

  /// Some loaders load templates from locations where the template
  /// sources may change (ie: file system or database).
  ///
  /// If `autoReload` is set to `true` (default) every time a template is
  /// requested the loader checks if the source changed and if yes, it
  /// will reload the template. For higher performance it's possible to
  /// disable that.
  final bool autoReload;

  /// A map of variables that are available in every template loaded by
  /// the environment.
  final Map<String, Object?> globals;

  /// A map of filters that are available in every template loaded by
  /// the environment.
  final Map<String, Function> filters;

  /// A map of tests that are available in every template loaded by
  /// the environment.
  final Map<String, Function> tests;

  /// A list of template modifiers.
  final List<Node Function(Node)> modifiers;

  /// A map of parsed templates loaded by the environment.
  final Map<String, Template> templates;

  /// A random generator used by some filters.
  final Random random;

  /// Get an attribute of an object.
  ///
  /// If `getAttribute` is not passed to the [Environment], the item is
  /// returned.
  final AttributeGetter getAttribute;

  /// Get an item of an object.
  final ItemGetter getItem;

  @override
  int get hashCode {
    return Object.hash(
      blockStart,
      blockEnd,
      variableStart,
      variableEnd,
      commentStart,
      commentEnd,
      lineStatementPrefix,
      lineCommentPrefix,
      trimBlocks,
      leftStripBlocks,
    );
  }

  /// The lexer for this environment.
  Lexer get lexer {
    return Lexer.cached(this);
  }

  @override
  bool operator ==(Object other) {
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

  /// Common filter and test caller.
  @internal
  Object? callCommon(
    Function function,
    List<Object?> positional,
    Map<Symbol, Object?> named,
    Context? context,
  ) {
    var pass = PassArgument.types[function];

    if (pass == PassArgument.context) {
      if (context == null) {
        throw TemplateRuntimeError(
            'Attempted to invoke context function without context');
      }

      positional = <Object?>[context, ...positional];
    } else if (pass == PassArgument.environment) {
      positional = <Object?>[this, ...positional];
    }

    return Function.apply(function, positional, named);
  }

  /// If [name] filter not found [TemplateRuntimeError] thrown.
  @internal
  Object? callFilter(
    String name,
    List<Object?> positional, [
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
    Context? context,
  ]) {
    if (filters[name] case var function?) {
      return callCommon(function, positional, named, context);
    }

    throw TemplateRuntimeError("No filter named '$name'");
  }

  /// If [name] not found throws [TemplateRuntimeError].
  @internal
  bool callTest(
    String name,
    List<Object?> positional, [
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
    Context? context,
  ]) {
    if (tests[name] case var function?) {
      return callCommon(function, positional, named, context) as bool;
    }

    throw TemplateRuntimeError("No test named '$name'");
  }

  /// Lex the given source and return a list of tokens.
  ///
  /// This can be useful for extension development and debugging templates.
  List<Token> lex(String source, {String? path}) {
    return lexer.tokenize(source, path: path);
  }

  /// Parse the list of tokens and return the AST nodes.
  ///
  /// This can be useful for debugging or to extract information from templates.
  Node scan(List<Token> tokens, {String? path}) {
    return Parser(this, path: path).scan(tokens);
  }

  /// Parse the source code and return the AST nodes.
  ///
  /// This can be useful for debugging or to extract information from templates.
  Node parse(String source, {String? path}) {
    return scan(lex(source), path: path);
  }

  /// Load a template from a source string without using [loader].
  Template fromString(String source, {String? path}) {
    var body = parse(source, path: path);

    for (var modifier in modifiers) {
      body = modifier(body);
    }

    if (optimize) {
      body = body.accept(const Optimizer(), Context(this));
    }

    body = body.accept(RuntimeCompiler(), <String>{});
    return Template.fromNode(this, body: body);
  }

  /// Load a template by name with `loader` and return a [Template].
  ///
  /// If the template does not exist a [TemplateNotFound] exception is thrown.
  Template getTemplate(String template) {
    if (loader case var loader?) {
      if (autoReload) {
        return templates[template] = loader.load(this, template);
      }

      return templates[template] ??= loader.load(this, template);
    }

    throw StateError('No loader for this environment specified');
  }

  /// Returns a list of templates for this environment.
  ///
  /// This requires that the loader supports the loader's
  /// [Loader.listTemplates] method.
  List<String> listTemplates() {
    if (loader case var loader?) {
      return loader.listTemplates();
    }

    throw StateError('No loader for this environment specified');
  }

  @protected
  static ContextFinalizer wrapFinalizer(Function function) {
    if (function case ContextFinalizer contextFinalizer) {
      return contextFinalizer;
    }

    if (function case EnvironmentFinalizer environmentFinalizer) {
      return (context, value) {
        return environmentFinalizer(context.environment, value);
      };
    }

    if (function case Finalizer finalizer) {
      return (context, value) {
        return finalizer(value);
      };
    }

    // TODO: add error message
    throw ArgumentError.value(function, 'finalize');
  }

  @protected
  static AttributeGetter wrapGetAttribute(
    AttributeGetter? attributeGetter,
    ItemGetter itemGetter,
  ) {
    if (attributeGetter == null) {
      return itemGetter;
    }

    return (attribute, object) {
      try {
        return attributeGetter(attribute, object);
      } on NoSuchMethodError {
        return itemGetter(attribute, object);
      }
    };
  }
}

/// {@template template}
/// The base `Template` class.
/// {@endtemplate}
class Template {
  /// {@macro template}
  factory Template(
    String source, {
    Environment? environment,
    String? path,
    String blockStart = '{%',
    String blockEnd = '%}',
    String variableStatr = '{{',
    String variableEnd = '}}',
    String commentStart = '{#',
    String commentEnd = '#}',
    String? lineCommentPrefix,
    String? lineStatementPrefix,
    bool trimBlocks = false,
    bool leftStripBlocks = false,
    String newLine = '\n',
    bool keepTrailingNewLine = false,
    bool optimize = true,
    ContextFinalizer finalize = defaults.finalize,
    bool autoEscape = false,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
    List<Node Function(Node)>? modifiers,
    Random? random,
    AttributeGetter? getAttribute,
    ItemGetter getItem = defaults.getItem,
  }) {
    environment ??= Environment(
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
      optimize: optimize,
      finalize: finalize,
      autoReload: false,
      globals: globals,
      filters: filters,
      tests: tests,
      modifiers: modifiers,
      random: random,
      getAttribute: getAttribute,
      getItem: getItem,
    );

    return environment.fromString(source, path: path);
  }

  Template.fromNode(this.environment, {this.path, required this.body});

  /// The environment used to parse and render template.
  final Environment environment;

  /// The path to the template if it was loaded.
  final String? path;

  /// Template body node.
  final Node body;

  /// If no arguments are given the context will be empty.
  String render([Map<String, Object?>? data]) {
    var buffer = StringBuffer();
    renderTo(buffer, data);
    return buffer.toString();
  }

  /// If no arguments are given the context will be empty.
  void renderTo(StringSink sink, [Map<String, Object?>? data]) {
    var context = StringSinkRenderContext(environment, sink, data: data);
    body.accept(const StringSinkRenderer(), context);
  }
}
