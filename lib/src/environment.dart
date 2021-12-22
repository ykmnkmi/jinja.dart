import 'dart:collection' show HashMap;
import 'dart:math' show Random;

import 'package:meta/meta.dart' show internal;

import 'context.dart';
import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'lexer.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'optimizer.dart';
import 'parser.dart';
import 'renderer.dart';
import 'visitor.dart';

/// Signature for the object attribute getter.
typedef FieldGetter = Object? Function(Object? object, String field);

/// Signature for the [Environment.finalize] field.
typedef Finalizer = Object? Function(Object? value);

// TODO(doc): update
enum PassArgument {
  context,
  environment,
}

/// Pass the [Context] as the first argument to the applied function when
/// called while rendering a template.
///
/// Can be used on functions, filters, and tests.
Function passContext(Function function) {
  Environment.passArguments[function] = PassArgument.context;
  return function;
}

/// Pass the [Environment] as the first argument to the applied function when
/// called while rendering a template.
///
/// Can be used on functions, filters, and tests.
Function passEnvironment(Function function) {
  Environment.passArguments[function] = PassArgument.environment;
  return function;
}

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
class Environment {
  /// Cached [Lexer]'s
  @internal
  static final Expando<Lexer> lexers = Expando<Lexer>();

  /// Cached [Parser]'s
  @internal
  static final Expando<Parser> parsers = Expando<Parser>();

  /// [PassArgument] values configurations for functions, filters, and tests.
  @internal
  static final Expando<PassArgument> passArguments = Expando<PassArgument>();

  /// If `loader` is not `null`, templates will be loaded
  Environment(
      {this.commentStart = defaults.commentStart,
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
      this.finalize = defaults.finalize,
      this.autoEscape = false,
      this.loader,
      this.autoReload = true,
      Map<String, Object?>? globals,
      Map<String, Function>? filters,
      Map<String, Function>? tests,
      Map<String, Template>? templates,
      Random? random,
      this.fieldGetter = defaults.fieldGetter})
      : assert(finalize is Finalizer ||
            finalize is Object? Function(Context context, Object? value) ||
            finalize is Object? Function(
                Environment environment, Object? value)),
        wrappedFinalize =
            finalize is Object? Function(Environment environment, Object? value)
                ? ((context, value) => finalize(context.environment, value))
                : finalize is Object? Function(Context context, Object? value)
                    ? finalize
                    : ((context, value) => finalize(value)),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        tests = HashMap<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
        random = random ?? Random() {
    if (globals != null) {
      this.globals.addAll(globals);
    }

    if (filters != null) {
      this.filters.addAll(filters);
    }

    if (tests != null) {
      this.tests.addAll(tests);
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
  /// Must be one of `'\r'`, `'\n'` or `'\r\n'`.
  final String newLine;

  /// Preserve the trailing newline when rendering templates.
  /// The default is `false`, which causes a single newline,
  /// if present, to be stripped from the end of the template.
  final bool keepTrailingNewLine;

  /// Should the optimizer be enabled?
  final bool optimized;

  /// A callable that can be used to process the result of a variable
  /// expression before it is output.
  ///
  /// For example one can convert `null` (`none`) implicitly into an empty
  /// string here.
  final Function finalize;

  @internal
  final Object? Function(Context context, Object? value) wrappedFinalize;

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

  /// A map of parsed templates loaded by the environment.
  final Map<String, Template> templates;

  /// [Random] generator used by some filters.
  final Random random;

  /// Function called by [getAttribute] to get object attribute.
  ///
  /// Default function throws [NoSuchMethodError].
  final FieldGetter fieldGetter;

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
        leftStripBlocks);
  }

  /// The lexer for this environment.
  Lexer get lexer {
    return lexers[this] ??= Lexer(this);
  }

  /// The parser for this environment.
  Parser get parser {
    return parsers[this] ??= Parser(this);
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

  /// Creates a copy of the environment with specified attributes overridden.
  Environment copyWith(
      {String? commentStart,
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
      Function? finalize,
      bool? autoEscape,
      Loader? loader,
      bool? autoReload,
      Map<String, Object?>? globals,
      Map<String, Function>? filters,
      Map<String, Function>? environmentFilters,
      Map<String, Function>? contextFilters,
      Map<String, Function>? tests,
      Random? random,
      FieldGetter? fieldGetter}) {
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
        finalize: finalize ?? this.finalize,
        autoEscape: autoEscape ?? this.autoEscape,
        loader: loader ?? this.loader,
        autoReload: autoReload ?? this.autoReload,
        globals: globals ?? this.globals,
        filters: filters ?? this.filters,
        tests: tests ?? this.tests,
        random: random ?? this.random,
        fieldGetter: fieldGetter ?? this.fieldGetter);
  }

  /// Lex the given sourcecode and return a list of [Token]'s.
  ///
  /// This can be useful for extension development and debugging templates.
  List<Token> lex(String source) {
    return lexer.tokenize(source);
  }

  /// Parse the sourcecode and return the abstract syntax tree.
  ///
  /// This is useful for debugging or to extract information from templates.
  List<Node> parse(String source) {
    var tokens = lex(source);
    return parser.scan(tokens);
  }

  /// Load a template from a source string without using [loader].
  Template fromString(String source, {String? path}) {
    var nodes = Parser(this, path: path).parse(source);
    var template = Template.parsed(this, nodes, path: path);

    if (optimized) {
      template.accept(const Optimizer(), Context(this));
    }

    return template;
  }

  /// Get an item or attribute of an object but prefer the attribute.
  Object? getAttribute(dynamic object, String attrbute) {
    return fieldGetter(object, attrbute);
  }

  /// Get an item or attribute of an object but prefer the item.
  Object? getItem(dynamic object, Object? key) {
    return object[key];
  }

  /// Common filter and test caller.
  @internal
  Object? callCommon(String name, List<Object?> positional,
      Map<Symbol, Object?> named, bool isFilter, Context? context) {
    var type = isFilter ? 'filter' : 'test';
    var map = isFilter ? filters : tests;
    var function = map[name];

    if (function == null) {
      throw TemplateRuntimeError('no $type named \'$name\'');
    }

    var pass = passArguments[function];

    if (pass == PassArgument.context) {
      if (context == null) {
        throw TemplateRuntimeError(
            'attempted to invoke context $type without context');
      }

      positional.insert(0, context);
    } else if (pass == PassArgument.environment) {
      positional.insert(0, this);
    }

    return Function.apply(function, positional, named);
  }

  /// If [name] not found throws [TemplateRuntimeError].
  Object? callFilter(String name, List<Object?> positional,
      [Map<Symbol, Object?> named = const <Symbol, Object?>{},
      Context? context]) {
    return callCommon(name, positional, named, true, context);
  }

  /// If [name] not found throws [TemplateRuntimeError].
  bool callTest(String name, List<Object?> positional,
      [Map<Symbol, Object?> named = const <Symbol, Object?>{},
      Context? context]) {
    return callCommon(name, positional, named, false, context) as bool;
  }

  /// Returns a list of templates for this environment.
  ///
  /// This requires that the loader supports the loader's
  /// [Loader.listTemplates] method.
  List<String> listTemplates() {
    var loader = this.loader;

    if (loader == null) {
      throw StateError('no loader for this environment specified');
    }

    return loader.listTemplates();
  }

  /// Load a template by name with [loader] and return a
  /// [Template]. If the template does not exist a [TemplateNotFound]
  /// exception is thrown.
  Template getTemplate(String template) {
    var loader = this.loader;

    if (loader == null) {
      throw StateError('no loader for this environment specified');
    }

    if (autoReload) {
      return templates[template] = loader.load(this, template);
    }

    return templates[template] ??= loader.load(this, template);
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
      {String? path,
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
      Function finalize = defaults.finalize,
      bool autoEscape = false,
      Map<String, Object?>? globals,
      Map<String, Function>? filters,
      Map<String, Function>? environmentFilters,
      Map<String, Function>? contextFilters,
      Map<String, Function>? tests,
      List<NodeVisitor>? modifiers,
      Random? random,
      FieldGetter fieldGetter = defaults.fieldGetter}) {
    Environment environment;

    if (parent != null) {
      environment = parent.copyWith(
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
          finalize: finalize,
          autoEscape: autoEscape,
          autoReload: false,
          globals: globals,
          filters: filters,
          environmentFilters: environmentFilters,
          contextFilters: contextFilters,
          tests: tests,
          random: random,
          fieldGetter: fieldGetter);
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
          finalize: finalize,
          autoEscape: autoEscape,
          autoReload: false,
          globals: globals,
          filters: filters,
          tests: tests,
          random: random,
          fieldGetter: fieldGetter);
    }

    return environment.fromString(source, path: path);
  }

  @internal
  Template.parsed(this.environment, this.nodes, {this.path})
      : blocks = <Block>[] {
    // TODO(refactoring): move modifiers to visitor

    for (var call in findAll<Call>()) {
      var expression = call.expression;

      if (expression is Attribute && expression.attribute == 'cycle') {
        var arguments = call.arguments;

        if (arguments != null) {
          call.arguments = arguments = <Expression>[Array(arguments)];

          var dArguments = call.dArguments;

          if (dArguments != null) {
            arguments.add(dArguments);
            call.dArguments = null;
          }
        }
      } else if (expression is Name && expression.name == 'namespace') {
        var arguments = <Expression>[...?call.arguments];
        call.arguments = null;
        var keywords = call.keywords;

        if (keywords != null && keywords.isNotEmpty) {
          var pairs =
              List<Pair>.generate(keywords.length, (i) => keywords[i].toPair());
          arguments.add(Dict(pairs));
          call.keywords = null;
        }

        var dArguments = call.dArguments;

        if (dArguments != null) {
          arguments.add(dArguments);
          call.dArguments = null;
        }

        var dKeywordArguments = call.dKeywords;

        if (dKeywordArguments != null) {
          arguments.add(dKeywordArguments);
          call.dKeywords = null;
        }

        if (arguments.isNotEmpty) {
          call.arguments = <Expression>[Array(arguments)];
        }
      }
    }

    accept(const ExpressionMapper(), (Expression expression) {
      if (expression is Attribute) {
        var value = expression.value;

        if (value is Name && (value.name == 'loop' || value.name == 'self')) {
          return Item.string(expression.attribute, value);
        }
      }

      return expression;
    });

    blocks.addAll(findAll<Block>());

    // TODO: remove/update
    if (nodes.isNotEmpty && nodes.first is Extends) {
      nodes.length = 1;
    }
  }

  /// The environment used to parse and render template.
  final Environment environment;

  /// Modified nodes.
  final List<Node> nodes;

  /// Modified blocks.
  final List<Block> blocks;

  /// The path to the template if it was loaded.
  final String? path;

  @override
  List<Node> get childrens {
    return nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplate(this, context);
  }

  /// It accepts the same arguments as [render].
  Iterable<String> generate([Map<String, Object?>? data]) {
    var context = RenderContext(environment, data: data);
    return accept(const IterableRenderer(), context);
  }

  /// If no arguments are given the context will be empty.
  String render([Map<String, Object?>? data]) {
    var buffer = StringBuffer();
    var context = StringSinkRenderContext(environment, buffer, data: data);
    accept(const StringSinkRenderer(), context);
    return buffer.toString();
  }

  @override
  String toString() {
    return path == null ? 'Template()' : 'Template($path)';
  }
}
