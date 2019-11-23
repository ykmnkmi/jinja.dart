// TODO: TokenStream

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:source_span/source_span.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'ext.dart';
import 'nodes.dart';

typedef TemplateModifier = void Function(Template template);

class Parser {
  static String getBeginRule(String rule) {
    String eRule = RegExp.escape(rule);
    return '(?:\\s*$eRule\\-|$eRule)\\s*';
  }

  static String getEndRule(String rule) {
    String eRule = RegExp.escape(rule);
    return '\\s*(?:\\-$eRule\\s*|$eRule)';
  }

  static RegExp getBlockStartReg(String rule, [bool leftStripBlocks = false]) {
    String blockStart = RegExp.escape(rule);

    if (leftStripBlocks) {
      return RegExp('(?:\\s*$blockStart\\-|^[ \\t]*$blockStart|$blockStart)\\s*', multiLine: true);
    }

    return RegExp('(?:\\s*$blockStart\\-|$blockStart)\\s*', multiLine: true);
  }

  static RegExp getBlockEndReg(String rule, [bool trimBlocks = false]) {
    String blockEnd = RegExp.escape(rule);
    String trim = trimBlocks ? '\n?' : '';
    return RegExp('\\s*(?:\\-$blockEnd\\s*|$blockEnd$trim)');
  }

  Parser(this.environment, String source, {this.path})
      : scanner = SpanScanner(source, sourceUrl: path),
        blockStartReg = getBlockStartReg(environment.blockStart, environment.leftStripBlocks),
        blockEndReg = getBlockEndReg(environment.blockEnd, environment.trimBlocks),
        variableStartReg = RegExp(getBeginRule(environment.variableStart)),
        variableEndReg = RegExp(getEndRule(environment.variableEnd)),
        commentStartReg = RegExp(getBeginRule(environment.commentStart)),
        commentEndReg = RegExp('.*' + getEndRule(environment.commentEnd)),
        extensions = <String, ExtensionParser>{} {
    Set<Extension> extensionsSet = environment.extensions.toSet();

    for (Extension ext in extensionsSet) {
      for (String tag in ext.tags) {
        extensions[tag] = ext.parse;
      }
    }
  }

  final Environment environment;
  final String path;
  final SpanScanner scanner;

  final RegExp blockStartReg;
  final RegExp blockEndReg;
  final RegExp variableStartReg;
  final RegExp variableEndReg;
  final RegExp commentStartReg;
  final RegExp commentEndReg;

  final Map<String, ExtensionParser> extensions;

  final Set<String> keywords = Set<String>.of(<String>['not', 'and', 'or', 'is', 'if', 'else']);

  final List<ExtendsStatement> extendsStatements = <ExtendsStatement>[];
  final List<List<Pattern>> endRulesStack = <List<Pattern>>[];
  final List<String> tagsStack = <String>[];

  RegExp getBlockEndRegFor(String rule, [bool withStart = false]) {
    if (withStart) {
      return RegExp(blockStartReg.pattern + RegExp.escape(rule) + blockEndReg.pattern, multiLine: true);
    }

    return RegExp(RegExp.escape(rule) + blockEndReg.pattern);
  }

  // before token stream
  final StreamController<Name> onParseNameController = StreamController<Name>.broadcast(sync: true);

  Stream<Name> get onParseName => onParseNameController.stream;

  final List<TemplateModifier> _templateModifiers = <TemplateModifier>[];

  void addTemplateModifier(TemplateModifier modifier) {
    _templateModifiers.add(modifier);
  }

  @alwaysThrows
  void error(String message) {
    throw TemplateSyntaxError(message, path: path, line: scanner.state.line, column: scanner.state.column);
  }

  void expect(Pattern pattern, {String name}) {
    if (scanner.scan(pattern)) return;

    if (name == null) {
      if (pattern is RegExp) {
        String source = pattern.pattern;
        name = '/$source/';
      } else {
        name = pattern.toString().replaceAll("\\", "\\\\").replaceAll('"', '\\"');
        name = '"$name"';
      }
    }

    throw TemplateSyntaxError(
      '$name expected',
      path: path,
      line: scanner.state.line,
      column: scanner.state.column,
    );
  }

  Template parse() {
    Node body = parseBody();
    Template template = Template.from(body: body, env: environment, path: path);

    for (TemplateModifier modifier in _templateModifiers) {
      modifier(template);
    }

    return template;
  }

  Node parseBody([List<Pattern> endRules = const <Pattern>[]]) {
    List<Node> nodes = subParse(endRules);
    return environment.optimize ? Interpolation.orNode(nodes) : Interpolation(nodes);
  }

  List<Node> subParse(List<Pattern> endRules) {
    StringBuffer buffer = StringBuffer();
    List<Node> body = <Node>[];

    if (endRules.isNotEmpty) endRulesStack.add(endRules);

    void flush() {
      if (buffer.isNotEmpty) {
        body.add(Text(buffer.toString()));
        buffer.clear();
      }
    }

    try {
      while (!scanner.isDone) {
        if (scanner.scan(blockStartReg)) {
          flush();
          if (endRules.isNotEmpty && testAll(endRules)) return body;
          body.add(parseStatement());
        } else if (scanner.scan(variableStartReg)) {
          flush();
          body.add(parseExpression());
          expect(variableEndReg);
        } else if (scanner.scan(commentStartReg)) {
          flush();
          expect(commentEndReg);
        } else {
          buffer.writeCharCode(scanner.readChar());
        }
      }

      flush();
    } finally {
      if (endRules.isNotEmpty) endRulesStack.removeLast();
    }

    return body;
  }

  bool testAll(List<Pattern> endRules) {
    for (Pattern rule in endRules) {
      if (scanner.matches(rule)) return true;
    }

    return false;
  }

  Node parseStatement() {
    expect(nameReg, name: 'statement tag');

    String tagName = scanner.lastMatch[1];
    bool popTag = true;
    tagsStack.add(tagName);

    expect(spaceReg);

    try {
      switch (tagName) {
        case 'extends':
          return parseExtends();
        case 'block':
          return parseBlock();
        case 'include':
          return parseInlcude();
        case 'for':
          return parseFor();
        case 'if':
          return parseIf();
        case 'set':
          return parseSet();
        case 'raw':
          return parseRaw();
        case 'filter':
          return parseFilterBlock();
        default:
          if (extensions.containsKey(tagName)) {
            ExtensionParser extParser = extensions[tagName];

            if (extParser == null) {
              error('parser not found: $tagName');
            }

            return extParser(this);
          }
      }

      tagsStack.removeLast();
      popTag = false;
      error('uknown tag: $tagName');
    } finally {
      if (popTag) tagsStack.removeLast();
    }
  }

  // TODO: update, check
  ExtendsStatement parseExtends() {
    Expression path = parsePrimary();
    expect(blockEndReg);

    ExtendsStatement extendsStatement = ExtendsStatement(path);

    extendsStatements.add(extendsStatement);

    LineScannerState state = scanner.state;

    addTemplateModifier((Template template) {
      Node body = template.body;
      Node first;

      if (body is Interpolation) {
        first = body.nodes.first;

        if (body.nodes.sublist(1).any((Node node) => node is ExtendsStatement)) {
          throw TemplateSyntaxError(
            'only one extends statement contains in template',
            path: scanner.sourceUrl,
            line: state.line,
            column: state.column,
          );
        }

        body.nodes
          ..clear()
          ..add(first);
      }
    });

    return extendsStatement;
  }

  BlockStatement parseBlock() {
    RegExp blockEndReg = getBlockEndRegFor('endblock');

    if (scanner.matches(this.blockEndReg)) {
      error('block name expected');
    }

    expect(nameReg, name: 'block name');

    String name = scanner.lastMatch[1];
    bool scoped = false;
    bool hasSuper = false;

    if (scanner.scan(spacePlusReg) && scanner.scan('scoped')) {
      scoped = true;
    }

    expect(this.blockEndReg);

    keywords.add('super');

    StreamSubscription<Name> subscription = onParseName.listen((Name node) {
      if (node.name == 'super') hasSuper = true;
    });

    Node body = parseBody(<Pattern>[blockEndReg]);
    subscription.cancel();
    keywords.remove('super');

    expect(blockEndReg);

    if (extendsStatements.isNotEmpty) {
      ExtendedBlockStatement block = ExtendedBlockStatement(name, path, body, scoped: scoped, hasSuper: hasSuper);

      for (ExtendsStatement extendsStatement in extendsStatements) {
        extendsStatement.blocks.add(block);
      }

      return block;
    }

    BlockStatement block = BlockStatement(name, path, body, scoped);

    addTemplateModifier((Template template) {
      template.blocks[block.name] = block;
    });

    return block;
  }

  IncludeStatement parseInlcude() {
    Expression oneOrList = parsePrimary();

    bool ignoreMissing = false;
    if (scanner.scan(' ignore missing')) ignoreMissing = true;

    bool withContext = true;

    if (scanner.scan(' without context')) {
      withContext = false;
    }

    scanner.scan(' with context');
    expect(blockEndReg);

    return IncludeStatement(oneOrList, ignoreMissing: ignoreMissing, withContext: withContext);
  }

  ForStatement parseFor() {
    RegExp elseReg = getBlockEndRegFor('else');
    RegExp forEndReg = getBlockEndRegFor('endfor');
    List<String> targets = parseAssignTarget();

    expect(spacePlusReg);
    expect('in');
    expect(spacePlusReg);

    Expression iterable = parseExpression(withCondition: false);
    Expression filter;

    if (scanner.scan(ifReg)) {
      filter = parseExpression(withCondition: false);
    }

    expect(blockEndReg);

    Node body = parseBody(<Pattern>[elseReg, forEndReg]);
    Node orElse;

    if (scanner.scan(elseReg)) {
      orElse = parseBody(<Pattern>[forEndReg]);
    }

    expect(forEndReg);

    return filter != null
        ? ForStatementWithFilter(targets, iterable, body, filter, orElse: orElse)
        : ForStatement(targets, iterable, body, orElse: orElse);
  }

  IfStatement parseIf() {
    RegExp elseReg = getBlockEndRegFor('else');
    RegExp ifEndReg = getBlockEndRegFor('endif');
    Map<Expression, Node> pairs = <Expression, Node>{};
    Node orElse;

    while (true) {
      if (scanner.matches(blockEndReg)) {
        error('expect statement body');
      }

      Expression condition = parseExpression();

      expect(blockEndReg);

      Node body = parseBody(<Pattern>['elif', elseReg, ifEndReg]);

      if (scanner.scan('elif')) {
        scanner.scan(spaceReg);
        pairs[condition] = body;
        continue;
      } else if (scanner.scan(elseReg)) {
        pairs[condition] = body;
        orElse = parseBody(<Pattern>[ifEndReg]);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    expect(ifEndReg);

    return IfStatement(pairs, orElse);
  }

  SetStatement parseSet() {
    RegExp setEndReg = getBlockEndRegFor('endset');

    expect(nameReg);

    String target = scanner.lastMatch[1];
    String field;

    if (scanner.scan(dotReg) && scanner.scan(nameReg)) {
      field = scanner.lastMatch[1];
    }

    if (scanner.scan(assignReg)) {
      if (scanner.matches(blockEndReg)) {
        error('expression expected');
      }

      Expression value = parseExpression(withCondition: false);

      expect(blockEndReg);

      return SetInlineStatement(target, value, field: field);
    }

    List<Filter> filters = <Filter>[];

    while (scanner.scan(pipeReg)) {
      Filter filter = parseFilter(hasLeadingPipe: false);

      if (filter == null) {
        error('filter expected but got ${filter.runtimeType}');
      }

      filters.add(filter);
    }

    expect(blockEndReg);

    Node body = parseBody(<Pattern>[setEndReg]);

    expect(setEndReg);

    if (filters.isNotEmpty) {
      body = FilterBlockStatement(filters, body);
    }

    return SetBlockStatement(target, body, field: field);
  }

  RawStatement parseRaw() {
    RegExp endRawReg = getBlockEndRegFor('endraw', true);

    expect(getBlockEndReg(environment.blockEnd));

    LineScannerState start = scanner.state;
    LineScannerState end = start;

    while (!scanner.isDone && !scanner.scan(endRawReg)) {
      scanner.readChar();
      end = scanner.state;
    }

    FileSpan span = scanner.spanFrom(start, end);
    return RawStatement(span.text);
  }

  FilterBlockStatement parseFilterBlock() {
    RegExp filterEndReg = getBlockEndRegFor('endfilter');

    if (scanner.matches(blockEndReg)) {
      error('filter expected');
    }

    List<Filter> filters = <Filter>[];

    while (scanner.scan(pipeReg)) {
      Filter filter = parseFilter(hasLeadingPipe: false);

      if (filter == null) {
        error('filter expected but got ${filter.runtimeType}');
      }

      filters.add(filter);
    }

    expect(blockEndReg);

    Node body = parseBody(<Pattern>[filterEndReg]);

    expect(filterEndReg);

    return FilterBlockStatement(filters, body);
  }

  List<String> parseAssignTarget({
    bool withTuple = true,
    List<Pattern> extraEndRules = const <Pattern>[],
  }) {
    CanAssign target;

    if (withTuple) {
      Object tuple = parseTuple(simplified: true, extraEndRules: extraEndRules);

      if (tuple is CanAssign) {
        target = tuple;
      } else {
        error('can\'t assign to "${target.runtimeType}"');
      }
    } else {
      expect(nameReg);

      target = Name(scanner.lastMatch[1]);
    }

    if (target.keys.any(keywords.contains)) {
      error('expected identifer got keyword');
    }

    return target.keys;
  }

  Expression parseExpression({bool withCondition = true}) {
    if (withCondition) {
      return parseCondition();
    }

    return parseOr();
  }

  Expression parseCondition() {
    Expression expr = parseOr();

    while (scanner.scan(ifReg)) {
      Expression testExpr = parseOr();
      Test test;
      Expression elseExpr;

      if (testExpr is Test) {
        test = testExpr;
      } else {
        test = Test('defined', expr: testExpr);
      }

      if (scanner.scan(elseReg)) {
        elseExpr = parseCondition();
      } else {
        elseExpr = Literal<Object>(null);
      }

      expr = Condition(test, expr, elseExpr);
    }

    return expr;
  }

  Expression parseOr() {
    Expression left = parseAnd();

    while (scanner.scan(orReg)) {
      left = Or(left, parseAnd());
    }

    return left;
  }

  Expression parseAnd() {
    Expression left = parseNot();

    while (scanner.scan(andReg)) {
      left = And(left, parseNot());
    }

    return left;
  }

  Expression parseNot() {
    if (scanner.scan(notReg)) {
      return Not(parseNot());
    }

    return parseCompare();
  }

  Expression parseCompare() {
    Expression left = parseMath1();

    while (true) {
      String op;

      if (scanner.scan(compareReg)) {
        op = scanner.lastMatch[1];
      } else if (scanner.scan(inReg)) {
        op = 'in';
      } else if (scanner.scan(notInReg)) {
        op = 'notin';
      } else {
        break;
      }

      Expression right = parseMath1();

      if (right == null) {
        error('Expected math expression');
      }

      switch (op) {
        case '>=':
          left = MoreEqual(left, right);
          break;
        case '>':
          left = More(left, right);
          break;
        case '<':
          left = Less(left, right);
          break;
        case '!=':
          left = Not(Equal(left, right));
          break;
        case '==':
          left = Equal(left, right);
          break;
        case 'in':
          left = Test('in', expr: left, args: <Expression>[right]);
          break;
        case 'notin':
          left = Not(Test('in', expr: left, args: <Expression>[right]));
      }
    }

    return left;
  }

  Expression parseMath1() {
    Expression left = parseConcat();

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) && scanner.scan(math1Reg)) {
      String op = scanner.lastMatch[1];
      Expression right = parseConcat();

      switch (op) {
        case '+':
          left = Add(left, right);
          break;
        case '-':
          left = Sub(left, right);
      }
    }

    return left;
  }

  Expression parseConcat() {
    List<Expression> args = <Expression>[parseMath2()];

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) && scanner.scan(tildaReg)) {
      args.add(parseMath2());
    }

    if (args.length == 1) {
      return args.single;
    }

    return Concat(args);
  }

  Expression parseMath2() {
    Expression left = parsePow();

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) && scanner.scan(math2Reg)) {
      String op = scanner.lastMatch[1];
      Expression right = parsePow();

      switch (op) {
        case '*':
          left = Mul(left, right);
          break;
        case '/':
          left = Div(left, right);
          break;
        case '//':
          left = FloorDiv(left, right);
          break;
        case '%':
          left = Mod(left, right);
      }
    }

    return left;
  }

  Expression parsePow() {
    Expression left = parseUnary();

    while (scanner.scan(powReg)) {
      left = Pow(left, parseUnary());
    }

    return left;
  }

  Expression parseUnary([bool withFilter = true]) {
    Expression expr;

    if (scanner.scan(unaryReg)) {
      switch (scanner.lastMatch[1]) {
        case '-':
          expr = Neg(parseUnary(false));
          break;
        case '+':
          expr = parseUnary(false);
          break;
      }
    } else {
      expr = parsePrimary();
    }

    if (scanner.isDone) {
      return expr;
    }

    expr = parsePostfix(expr);

    if (withFilter) {
      expr = parsePostfixFilter(expr);
    }

    return expr;
  }

  Expression parsePrimary() {
    Expression expr;

    if (scanner.scan('false')) {
      expr = Literal<bool>(false);
    } else if (scanner.scan('true')) {
      expr = Literal<bool>(true);
    } else if (scanner.scan('none')) {
      expr = Literal<Object>(null);
    } else if (scanner.scan(nameReg)) {
      String name = scanner.lastMatch[1];
      Name nameExpr = Name(name);
      expr = nameExpr;
      onParseNameController.add(nameExpr);
    } else if (scanner.scan(stringStartReg)) {
      String body;

      switch (scanner.lastMatch[1]) {
        case '"':
          expect(stringContentDQReg, name: 'string content and double quote');
          body = scanner.lastMatch[1];
          break;
        case "'":
          expect(stringContentSQReg, name: 'string content and single quote');
          body = scanner.lastMatch[1];
      }

      expr = Literal<Object>(body);
    } else if (scanner.scan(digitReg)) {
      String integer = scanner.lastMatch[1];

      if (scanner.scan(fractionalReg)) {
        expr = Literal<double>(double.tryParse(integer + scanner.lastMatch[0]));
      } else {
        expr = Literal<int>(int.tryParse(integer));
      }
    } else if (scanner.matches(lBracketReg)) {
      expr = parseList();
    } else if (scanner.matches(lBraceReg)) {
      expr = parseMap();
    } else if (scanner.scan(lParenReg)) {
      expr = parseTuple();
      expect(rParenReg);
    } else {
      error('primary expression expected');
    }

    return expr;
  }

  Expression parseTuple({
    bool simplified = false,
    bool withCondition = true,
    List<Pattern> extraEndRules = const <Pattern>[],
    bool explicitParentheses = false,
  }) {
    Expression Function() $parse;

    if (simplified) {
      $parse = parsePrimary;
    } else if (withCondition) {
      $parse = parseExpression;
    } else {
      $parse = () => parseExpression(withCondition: true);
    }

    List<Expression> args = <Expression>[];
    bool isTuple = false;

    while (!scanner.scan(rParenReg)) {
      if (args.isNotEmpty) {
        expect(commaReg);
      }

      if (isTupleEnd(extraEndRules)) {
        break;
      }

      args.add($parse());

      if (scanner.matches(commaReg)) {
        isTuple = true;
      } else {
        break;
      }
    }

    if (!isTuple) {
      if (args.isNotEmpty) return args.single;
      if (!explicitParentheses) error('expected an expression');
    }

    return TupleExpression(args);
  }

  bool isTupleEnd([List<Pattern> extraEndRules = const <Pattern>[]]) {
    if (testAll(<Pattern>[variableEndReg, blockEndReg, rParenReg])) return true;
    if (extraEndRules.isNotEmpty) return testAll(extraEndRules);
    return false;
  }

  Expression parseList() {
    expect(lBracketReg);

    List<Expression> items = <Expression>[];

    while (!scanner.scan(rBracketReg)) {
      if (items.isNotEmpty) expect(commaReg);
      if (scanner.scan(rBracketReg)) break;
      items.add(parseExpression());
    }

    if (environment.optimize && items.every((Expression item) => item is Literal)) {
      return Literal<List<Object>>(
          items.map((Expression item) => (item as Literal<Object>).value).toList(growable: false));
    }

    return ListExpression(items);
  }

  Expression parseMap() {
    expect(lBraceReg);

    Map<Expression, Expression> items = <Expression, Expression>{};

    while (!scanner.scan(rBraceReg)) {
      if (items.isNotEmpty) expect(commaReg);

      Expression key = parseExpression();

      expect(colonReg, name: 'dict entry delimeter');

      items[key] = parseExpression();
    }

    if (environment.optimize &&
        items.entries.every((MapEntry<Expression, Expression> item) => item.key is Literal && item.value is Literal)) {
      return Literal<Map<Object, Object>>(items.map((Expression key, Expression value) =>
          MapEntry<Object, Object>((key as Literal<Object>).value, (value as Literal<Object>).value)));
    }

    return MapExpression(items);
  }

  Expression parsePostfix(Expression expr) {
    while (true) {
      if (scanner.matches(dotReg) || scanner.matches(lBracketReg)) {
        expr = parseSubscript(expr);
      } else if (scanner.matches(lParenReg)) {
        expr = parseCall(expr: expr);
      } else {
        break;
      }
    }

    return expr;
  }

  Expression parsePostfixFilter(Expression expr) {
    while (true) {
      if (scanner.matches(pipeReg)) {
        expr = parseFilter(expr: expr);
      } else if (scanner.matches(isReg)) {
        expr = parseTest(expr);
      } else if (scanner.matches(lParenReg)) {
        expr = parseCall(expr: expr);
      } else {
        break;
      }
    }

    return expr;
  }

  Expression parseSubscript(Expression expr) {
    if (scanner.scan(dotReg)) {
      expect(nameReg, name: 'field identifier');

      return Field(expr, scanner.lastMatch[1]);
    }

    if (scanner.scan(lBracketReg)) {
      Expression item = parseExpression();

      expect(rBracketReg);

      return Item(expr, item);
    }

    error('expected subscript expression');
  }

  Call parseCall({Expression expr}) {
    expect(lParenReg);

    List<Expression> args = <Expression>[];
    Map<String, Expression> kwargs = <String, Expression>{};
    Expression argsDyn, kwargsDyn;
    bool requireComma = false;

    while (!scanner.scan(rParenReg)) {
      if (requireComma) {
        expect(commaReg);

        if (scanner.scan(rParenReg)) break;
      }

      if (scanner.scan('**')) {
        kwargsDyn = parseExpression();
      } else if (scanner.scan('*')) {
        argsDyn = parseExpression();
      } else if (scanner.scan(RegExp(nameReg.pattern + assignReg.pattern)) && argsDyn == null && kwargsDyn == null) {
        String arg = scanner.lastMatch[1];
        String key = arg == 'default' ? '\$default' : arg;
        kwargs[key] = parseExpression();
      } else if (kwargs.isEmpty && argsDyn == null && kwargsDyn == null) {
        args.add(parseExpression());
      } else {
        error('message');
      }

      requireComma = true;
    }

    return Call(expr, args: args, kwargs: kwargs, argsDyn: argsDyn, kwargsDyn: kwargsDyn);
  }

  Filter parseFilter({Expression expr, bool hasLeadingPipe = true}) {
    if (hasLeadingPipe) expect(pipeReg);

    if (expr != null) {
      do {
        expr = _parseFilter(expr);
      } while (scanner.scan(pipeReg));
    } else {
      expr = _parseFilter(expr);
    }

    return expr as Filter;
  }

  Expression _parseFilter(Expression expr) {
    expect(nameReg, name: 'filter name');

    String name = scanner.lastMatch[1];

    if (scanner.matches(lParenReg)) {
      Call call = parseCall();
      expr = Filter(name, expr: expr, args: call.args, kwargs: call.kwargs);
    } else {
      expr = Filter(name, expr: expr);
    }

    return expr;
  }

  Expression parseTest(Expression expr) {
    List<Expression> args = <Expression>[];
    Map<String, Expression> kwargs = <String, Expression>{};
    bool negated = false;

    scanner.scan(isReg);
    if (scanner.scan(notReg)) negated = true;
    expect(nameReg, name: 'test name');

    String name = scanner.lastMatch[1];

    if (scanner.matches(lParenReg)) {
      Call call = parseCall();
      args.addAll(call.args);
      kwargs.addAll(call.kwargs);
    } else if (scanner.matches(inlineSpacePlusReg) &&
        !testAll(<Pattern>[elseReg, orReg, andReg, variableEndReg, blockEndReg])) {
      scanner.scan(spacePlusReg);
      Expression arg = parsePrimary();

      if (arg is Name) {
        if (!<String>['else', 'or', 'and'].contains(arg.name)) {
          if (arg.name == 'is') {
            error('You cannot chain multiple tests with is');
          }
        }
      }

      args.add(arg);
    }

    expr = Test(name, expr: expr, args: args, kwargs: kwargs);

    if (negated) {
      expr = Not(expr);
    }

    return expr;
  }

  static final RegExp elseReg = RegExp(r'\s+else\s+');
  static final RegExp ifReg = RegExp(r'\s+if\s+');
  static final RegExp orReg = RegExp(r'\s+or\s+');
  static final RegExp andReg = RegExp(r'\s+and\s+');
  static final RegExp compareReg = RegExp(r'\s*(>=|>|<=|<|!=|==)\s*');
  static final RegExp math1Reg = RegExp(r'\s*(\+|-)\s*');
  static final RegExp tildaReg = RegExp(r'\s*~\s*');
  static final RegExp math2Reg = RegExp(r'\s*(//|/|\*|%)\s*');
  static final RegExp powReg = RegExp(r'\s*\*\*\s*');
  static final RegExp assignReg = RegExp(r'\s*=\s*');
  static final RegExp spacePlusReg = RegExp(r'\s+', multiLine: true);
  static final RegExp inlineSpacePlusReg = RegExp(r'\s+');
  static final RegExp spaceReg = RegExp(r'\s*', multiLine: true);
  static final RegExp inlineSpaceReg = RegExp(r'\s*');
  static final RegExp newLineReg = RegExp(r'(\r\n|\n)');

  static final RegExp inReg = RegExp(r'(\r\n|\n)?\s+in(\r\n|\n)?\s+');
  static final RegExp notInReg = RegExp(r'(\r\n|\n)?\s+not\s+in(\r\n|\n)?\s+');
  static final RegExp notReg = RegExp(r'not\s+');
  static final RegExp isReg = RegExp(r'(\r\n|\n)?\s+is(\r\n|\n)?\s+');
  static final RegExp pipeReg = RegExp(r'\s*\|\s*');
  static final RegExp unaryReg = RegExp(r'(-|\+)');

  static final RegExp colonReg = RegExp(r'\s*:\s*');
  static final RegExp commaReg = RegExp(r'(\r\n|\n)?\s*,(\r\n|\n)?\s*');
  static final RegExp rBraceReg = RegExp(r'\s*\}');
  static final RegExp lBraceReg = RegExp(r'\{\s*');
  static final RegExp rBracketReg = RegExp(r'\s*\]');
  static final RegExp lBracketReg = RegExp(r'\[\s*');
  static final RegExp rParenReg = RegExp(r'\s*\)');
  static final RegExp lParenReg = RegExp(r'\(\s*');
  static final RegExp dotReg = RegExp(r'\.');
  static final RegExp digitReg = RegExp(r'(\d+)');
  static final RegExp fractionalReg = RegExp(r'\.(\d+)');
  static final RegExp stringContentDQReg = RegExp('([^"]*)"');
  static final RegExp stringContentSQReg = RegExp("([^']*)'");
  static final RegExp stringStartReg = RegExp('(\\\'|\\")');
  static final RegExp nameReg = RegExp('([a-zA-Z][a-zA-Z0-9]*)');
}
