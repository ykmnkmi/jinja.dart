import 'dart:collection' show HashMap;
import 'dart:math' show Random;

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
import 'package:jinja/src/visitor.dart';
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
typedef AttributeGetter = Object? Function(Object? object, String attribute);

/// A [Function] that can be used to get object item.
///
/// Used by `object['item']` expression.
typedef ItemGetter = Object? Function(Object? object, Object? item);

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
    this.autoEscape = false,
    this.loader,
    this.autoReload = true,
    Map<String, Object?>? globals,
    Map<String, Function>? filters,
    Map<String, Function>? tests,
    List<NodeVisitor>? modifiers,
    Map<String, Template>? templates,
    Random? random,
    AttributeGetter? getAttribute,
    this.getItem = defaults.getItem,
  })  : finalize = wrapFinalizer(finalize),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        tests = HashMap<String, Function>.of(defaults.tests),
        modifiers = List<NodeVisitor>.of(defaults.modifiers),
        templates = HashMap<String, Template>(),
        random = random ?? Random(),
        getAttribute = wrapGetAttribute(getAttribute, getItem) {
    if (newLine != '\r' && newLine != '\n' && newLine != '\r\n') {
      // TODO: add error message
      throw ArgumentError.value(newLine, 'newLine');
    }

    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
    }

    if (modifiers != null) {
      this.modifiers.addAll(modifiers);
    }

    if (templates != null) {
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

  /// If set to `true` the XML/HTML autoescaping feature is enabled by
  /// default.
  final bool autoEscape;

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
  final List<NodeVisitor> modifiers;

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
    var function = filters[name];

    if (function == null) {
      throw TemplateRuntimeError("No filter named '$name'");
    }

    return callCommon(function, positional, named, context);
  }

  /// If [name] not found throws [TemplateRuntimeError].
  @internal
  bool callTest(
    String name,
    List<Object?> positional, [
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
    Context? context,
  ]) {
    var function = tests[name];

    if (function == null) {
      throw TemplateRuntimeError("No test named '$name'");
    }

    return callCommon(function, positional, named, context) as bool;
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
  List<Node> scan(List<Token> tokens, {String? path}) {
    return Parser(this, path: path).scan(tokens);
  }

  /// Parse the source code and return the AST nodes.
  ///
  /// This can be useful for debugging or to extract information from templates.
  List<Node> parse(String source, {String? path}) {
    var tokens = lex(source);
    return scan(tokens, path: path);
  }

  /// Load a template from a source string without using [loader].
  Template fromString(String source, {String? path}) {
    var body = Parser(this, path: path).parse(source);

    for (var modifier in modifiers) {
      modifier(body);
    }

    if (optimize) {
      body.accept(const Optimizer(), Context(this));
    }

    return Template.parsed(this, body, path: path);
  }

  /// Load a template by name with `loader` and return a [Template].
  ///
  /// If the template does not exist a [TemplateNotFound] exception is thrown.
  Template getTemplate(String template) {
    var loader = this.loader;

    if (loader == null) {
      throw StateError('No loader for this environment specified');
    }

    if (autoReload) {
      return templates[template] = loader.load(this, template);
    }

    return templates[template] ??= loader.load(this, template);
  }

  /// Returns a list of templates for this environment.
  ///
  /// This requires that the loader supports the loader's
  /// [Loader.listTemplates] method.
  List<String> listTemplates() {
    var loader = this.loader;

    if (loader == null) {
      throw StateError('No loader for this environment specified');
    }

    return loader.listTemplates();
  }

  @protected
  static ContextFinalizer wrapFinalizer(Function function) {
    if (function is ContextFinalizer) {
      return function;
    }

    if (function is Object Function(Environment environment, Object? value)) {
      Object finalize(Context context, Object? value) {
        return function(context.environment, value);
      }

      return finalize;
    }

    if (function is Object Function(Object? value)) {
      Object finalize(Context context, Object? value) {
        return function(value);
      }

      return finalize;
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

    Object? getAttribute(Object? object, String field) {
      try {
        return attributeGetter(object, field);
      } on NoSuchMethodError {
        return itemGetter(object, field);
      }
    }

    return getAttribute;
  }
}

/// {@template template}
/// The base `Template` class.
/// {@endtemplate}
// TODO(template): add note about environment modification
class Template extends Node {
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
    List<NodeVisitor>? modifiers,
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
      autoEscape: autoEscape,
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

  factory Template.fromNodes(
    Environment environment,
    List<Node> nodes, {
    String? path,
  }) {
    Node body;

    if (nodes.isEmpty) {
      body = Data();
    } else if (nodes.first is Extends) {
      body = nodes.first;
    } else {
      body = Output.orSingle(nodes);
    }

    var blocks = <Block>[for (var node in nodes) ...node.findAll<Block>()];

    var template = Template.parsed(
      environment,
      body,
      path: path,
      blocks: blocks,
    );

    for (var modifier in environment.modifiers) {
      modifier(template);
    }

    if (environment.optimize) {
      template.accept(const Optimizer(), Context(environment));
    }

    return template;
  }

  @internal
  Template.parsed(
    this.environment,
    this.body, {
    this.path,
    List<Block>? blocks,
  }) : blocks = blocks ?? <Block>[];

  /// The environment used to parse and render template.
  final Environment environment;

  /// The path to the template if it was loaded.
  final String? path;

  /// Template body node.
  final Node body;

  /// Template blocks.
  final List<Block> blocks;

  @override
  List<Node> get childrens {
    return <Node>[body];
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplate(this, context);
  }

  /// If no arguments are given the context will be empty.
  String render([Map<String, Object?>? data]) {
    var buffer = StringBuffer();
    var context = StringSinkRenderContext(environment, buffer, data: data);
    accept(const StringSinkRenderer(), context);
    return buffer.toString();
  }

  /// If no arguments are given the context will be empty.
  void renderTo(StringSink sink, [Map<String, Object?>? data]) {
    var context = StringSinkRenderContext(environment, sink, data: data);
    accept(const StringSinkRenderer(), context);
  }
}
