import 'dart:collection' show HashMap;
import 'dart:math' show Random;

import 'package:meta/meta.dart' show internal;

import 'defaults.dart' as defaults;
import 'exceptions.dart';
import 'lexer.dart';
import 'loaders.dart';
import 'nodes.dart';
import 'optimizer.dart';
import 'parser.dart';
import 'reader.dart';
import 'renderer.dart';
import 'runtime.dart';
import 'visitor.dart';

typedef Finalizer = Object? Function(Object? value);

typedef ContextFinalizer = Object? Function(Context context, Object? value);

typedef EnvironmentFinalizer = Object? Function(
    Environment environment, Object? value);

typedef FieldGetter = Object? Function(Object? object, String field);

/// The core component of Jinja 2 is the Environment. It contains
/// important shared variables like configuration, filters, tests and others.
/// Instances of this class may be modified if they are not shared and if no
/// template was loaded so far.
class Environment {
  /// Cached [Lexer]'s
  static final Expando<Lexer> lexers = Expando('lexerCache');

  /// Cached [Parser]'s
  static final Expando<Parser> parsers = Expando('parserCache');

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
      Function finalize = defaults.finalize,
      this.autoEscape = false,
      this.loader,
      this.autoReload = true,
      Map<String, Object?>? globals,
      Map<String, Function>? filters,
      Map<String, Function>? environmentFilters,
      Map<String, Function>? contextFilters,
      Map<String, Function>? tests,
      Map<String, Template>? templates,
      List<NodeVisitor>? modifiers,
      Random? random,
      this.fieldGetter = defaults.fieldGetter})
      : assert(finalize is Finalizer ||
            finalize is ContextFinalizer ||
            finalize is EnvironmentFinalizer),
        finalize = finalize is EnvironmentFinalizer
            ? ((context, value) => finalize(context.environment, value))
            : finalize is ContextFinalizer
                ? finalize
                : ((context, value) => finalize(value)),
        globals = HashMap<String, Object?>.of(defaults.globals),
        filters = HashMap<String, Function>.of(defaults.filters),
        environmentFilters =
            HashMap<String, Function>.of(defaults.environmentFilters),
        contextFilters = HashMap<String, Function>.of(defaults.contextFilters),
        tests = HashMap<String, Function>.of(defaults.tests),
        templates = HashMap<String, Template>(),
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

  // TODO: docs
  final Map<String, Function> environmentFilters;

  // TODO: docs
  final Map<String, Function> contextFilters;

  /// A map of tests that are available in every template loaded by
  /// the environment.
  final Map<String, Function> tests;

  // TODO: docs
  final Map<String, Template> templates;

  // TODO: docs
  final Random random;

  // TODO: docs
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

  /// If [name] not found throws [TemplateRuntimeError].
  @internal
  Object? callFilter(
      String name, List<Object?> positional, Map<Symbol, Object?> named,
      [Context? context]) {
    Function? filter;

    if (filters.containsKey(name)) {
      filter = filters[name];
    } else if (environmentFilters.containsKey(name)) {
      filter = environmentFilters[name];
      positional.insert(0, this);
    } else if (contextFilters.containsKey(name)) {
      if (context == null) {
        throw TemplateRuntimeError(
            'attempted to invoke context filter without context');
      }

      filter = contextFilters[name];
      positional.insert(0, context);
    }

    if (filter == null) {
      throw TemplateRuntimeError('no filter named $name');
    }

    return Function.apply(filter, positional, named);
  }

  /// If [name] not found throws [TemplateRuntimeError].
  @internal
  bool callTest(
      String name, List<Object?> positional, Map<Symbol, Object?> named) {
    var test = tests[name];

    if (test == null) {
      throw TemplateRuntimeError('no test named $name');
    }

    return Function.apply(test, positional, named) as bool;
  }

  /// Get an item or attribute of an object but prefer the attribute.
  @internal
  Object? getAttribute(dynamic object, String field) {
    try {
      return fieldGetter(object, field);
    } on NoSuchMethodError {
      return object[field];
    }
  }

  /// Get an item or attribute of an object but prefer the item.
  @internal
  Object? getItem(dynamic object, Object? key) {
    return object[key];
  }

  /// Lex the given sourcecode and return a list of [Token]'s.
  ///
  /// This can be useful for extension development and debugging templates.
  @internal
  List<Token> lex(String source) {
    // TODO: handle error
    return lexer.tokenize(source);
  }

  /// Parse the sourcecode and return the abstract syntax tree.
  ///
  /// This is useful for debugging or to extract information from templates.
  @internal
  List<Node> parse(List<Token> tokens) {
    // TODO: handle error
    var reader = TokenReader(tokens);
    return parser.scan(reader);
  }

  /// Load a template from a source string without using [loader].
  Template fromString(String source, {String? path}) {
    var nodes = Parser(this, path: path).parse(source);
    var template = Template.parsed(this, nodes, path: path);
    return optimized
        ? const Optimizer().visitTemplate(template, Context(this))
        : template;
  }

  /// Load a template by name with [loader] and return a
  /// [Template]. If the template does not exist a [TemplateNotFound]
  /// exception is thrown.
  Template getTemplate(String template) {
    // TODO: handle error
    var loader = this.loader!;

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
    // TODO: handle error
    return loader!.listTemplates();
  }

  /// Create a new overlay environment that shares all the data with
  /// the current environment except the overridden attributes.
  Environment overlay(
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
      environment = parent.overlay(
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
          environmentFilters: environmentFilters,
          contextFilters: contextFilters,
          tests: tests,
          modifiers: modifiers,
          random: random,
          fieldGetter: fieldGetter);
    }

    return environment.fromString(source, path: path);
  }

  // TODO: docs
  Template.parsed(this.environment, this.nodes, {this.path})
      : hasSelf = false,
        blocks = <Block>[] {
    for (var node in findAll<Name>()) {
      if (node.name == 'self') {
        hasSelf = true;
        break;
      }
    }

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
              keywords.map<Pair>((keyword) => keyword.toPair()).toList();
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

  // TODO: docs
  Environment environment;

  // TODO: docs
  List<Node> nodes;

  // TODO: docs
  List<Block> blocks;

  // TODO: docs
  bool hasSelf;

  // TODO: docs
  String? path;

  @override
  List<Node> get childrens {
    return nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplate(this, context);
  }

  // TODO: docs
  String render([Map<String, Object?>? data]) {
    var buffer = StringBuffer();
    var context = RenderContext(environment, buffer, data: data);
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
