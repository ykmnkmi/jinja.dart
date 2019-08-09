import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import 'nodes.dart';
import 'environment.dart';

typedef T ParserCallback<T extends Node>(Parser parser);

class Parser {
  static String getBeginRule(String rule) {
    final eRule = RegExp.escape(rule);
    return '(?:\\s*$eRule\\-|$eRule)\\s*';
  }

  static String getEndRule(String rule) {
    String eRule = RegExp.escape(rule);
    return '\\s*(?:\\-$eRule\\s*|$eRule)';
  }

  static RegExp getBlockStartReg(Environment environment) {
    final blockStart = RegExp.escape(environment.blockStart);
    final lStrip = environment.leftStripBlocks ? '^\\s*' : '';
    return RegExp('(?:\\s*$blockStart\\-|$lStrip$blockStart)\\s*', multiLine: true);
  }

  static RegExp getBlockEndReg(Environment environment) {
    final blockEnd = RegExp.escape(environment.blockEnd);
    final trimBlocks = environment.trimBlocks ? '\n' : '';
    return RegExp('\\s*(?:\\-$blockEnd\\s*|$blockEnd)$trimBlocks');
  }

  Parser(this.environment, String source, {this.path})
      : scanner = SpanScanner(source, sourceUrl: path),
        blockStartReg = getBlockStartReg(environment),
        blockEndReg = getBlockEndReg(environment),
        variableStartReg = RegExp(getBeginRule(environment.variableStart)),
        variableEndReg = RegExp(getEndRule(environment.variableEnd)),
        commentStartReg = RegExp(getBeginRule(environment.commentStart)),
        commentEndReg = RegExp('.*' + getEndRule(environment.commentEnd));

  final Environment environment;
  final String path;
  final SpanScanner scanner;

  final RegExp blockStartReg;
  final RegExp blockEndReg;
  final RegExp variableStartReg;
  final RegExp variableEndReg;
  final RegExp commentStartReg;
  final RegExp commentEndReg;

  final List<List<Pattern>> endRulesStack = <List<Pattern>>[];
  final List<String> tagsStack = <String>[];

  RegExp getBlockEndRegFor(String rule) {
    return RegExp(RegExp.escape(rule) + blockEndReg.pattern);
  }

  @alwaysThrows
  void error(String message) {
    throw TemplateSyntaxError(
        message, scanner.state.line, scanner.state.position);
  }

  bool testAll(List<Pattern> endRules) {
    for (Pattern rule in endRules) {
      if (scanner.matches(rule)) return true;
    }

    return false;
  }

  Template parse() {
    return Template.from(
      body: Interpolation(subParse()),
      environment: environment,
      path: path,
    );
  }

  List<Node> subParse([List<Pattern> endRules = const <Pattern>[]]) {
    final buffer = StringBuffer();
    final body = <Node>[];

    if (endRules.isNotEmpty) endRulesStack.add(endRules);

    void flush() {
      if (buffer.isNotEmpty) {
        body.add(Text('$buffer'));
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
          scanner.expect(variableEndReg);
        } else if (scanner.scan(commentStartReg)) {
          flush();
          scanner.expect(commentEndReg);
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

  bool isTupleEnd([List<Pattern> extraEndRules = const <Pattern>[]]) {
    if (testAll(<Pattern>[variableEndReg, blockEndReg, rParenReg])) return true;
    if (extraEndRules.isNotEmpty) return testAll(extraEndRules);
    return false;
  }

  Node parseStatement() {
    scanner.expect(nameReg, name: 'tag name expected');

    final tagName = scanner.lastMatch[1];
    bool popTag = true;

    tagsStack.add(tagName);

    scanner.expect(spacePlusReg);

    try {
      if (environment.extensions.containsKey(tagName)) {
        return environment.extensions[tagName](this);
      }

      tagsStack.removeLast();
      popTag = false;
      error('uknown tag: $tagName');
    } finally {
      if (popTag) tagsStack.removeLast();
    }
  }

  Node parseStatements(List<Pattern> endRules) {
    final nodes = subParse(endRules);
    if (scanner.isDone) error('scanner is done');
    return Interpolation(nodes);
  }

  List<String> parseAssignTarget({
    bool withTuple = true,
    List<Pattern> extraEndRules = const <Pattern>[],
  }) {
    Assignable target;

    if (withTuple) {
      final dynamic tuple =
          parseTuple(simplified: true, extraEndRules: extraEndRules);

      if (tuple is Assignable) {
        target = tuple;
      } else {
        error('can\'t assign to "${target.runtimeType}"');
      }
    } else {
      scanner.expect(nameReg);

      target = Name(scanner.lastMatch[1]);
    }

    if (target.keys.any(environment.keywords.contains)) {
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
    var expr = parseOr();

    while (scanner.scan(ifReg)) {
      final testExpr = parseOr();
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
        elseExpr = Literal(null);
      }

      expr = Condition(test, expr, elseExpr);
    }

    return expr;
  }

  Expression parseOr() {
    var left = parseAnd();

    while (scanner.scan(orReg)) {
      left = Or(left, parseAnd());
    }

    return left;
  }

  Expression parseAnd() {
    var left = parseNot();

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
    var left = parseMath1();

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

      final right = parseMath1();

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
    var left = parseConcat();

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) &&
        scanner.scan(math1Reg)) {
      final op = scanner.lastMatch[1];
      final right = parseConcat();

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
    final args = <Expression>[parseMath2()];

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) &&
        scanner.scan(tildaReg)) {
      args.add(parseMath2());
    }

    if (args.length == 1) {
      return args.single;
    }

    return Concat(args);
  }

  Expression parseMath2() {
    var left = parsePow();

    while (!testAll(<Pattern>[variableEndReg, blockEndReg]) &&
        scanner.scan(math2Reg)) {
      final op = scanner.lastMatch[1];
      final right = parsePow();

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
    var left = parseUnary();

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
      expr = Literal(false);
    } else if (scanner.scan('true')) {
      expr = Literal(true);
    } else if (scanner.scan('none')) {
      expr = Literal(null);
    } else if (scanner.scan(nameReg)) {
      final name = scanner.lastMatch[1];
      expr = Name(name);
    } else if (scanner.scan(stringStartReg)) {
      String body;

      switch (scanner.lastMatch[1]) {
        case '"':
          scanner.expect(stringContentDQReg,
              name: 'string content and double quote');
          body = scanner.lastMatch[1];
          break;
        case "'":
          scanner.expect(stringContentSQReg,
              name: 'string content and single quote');
          body = scanner.lastMatch[1];
      }

      expr = Literal(body);
    } else if (scanner.scan(digitReg)) {
      final integer = scanner.lastMatch[1];

      if (scanner.scan(fractionalReg)) {
        expr = Literal(double.tryParse(integer + scanner.lastMatch[0]));
      } else {
        expr = Literal(int.tryParse(integer));
      }
    } else if (scanner.matches(lBracketReg)) {
      expr = parseList();
    } else if (scanner.matches(lBraceReg)) {
      expr = parseMap();
    } else if (scanner.scan(lParenReg)) {
      expr = parseTuple();
      scanner.expect(rParenReg);
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

    final args = <Expression>[];
    bool isTuple = false;

    while (!scanner.scan(rParenReg)) {
      if (args.isNotEmpty) {
        scanner.expect(commaReg);
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

  Expression parseList() {
    scanner.expect(lBracketReg);

    final items = <Expression>[];

    while (!scanner.scan(rBracketReg)) {
      if (items.isNotEmpty) scanner.expect(commaReg);
      if (scanner.scan(rBracketReg)) break;
      items.add(parseExpression());
    }

    if (environment.optimize && items.every((item) => item is Literal)) {
      return Literal(
          items.map((item) => (item as Literal).value).toList(growable: false));
    }

    return ListExpression(items);
  }

  Expression parseMap() {
    scanner.expect(lBraceReg);

    final items = <Expression, Expression>{};

    while (!scanner.scan(rBraceReg)) {
      if (items.isNotEmpty) scanner.expect(commaReg);
      final key = parseExpression();
      scanner.expect(colonReg, name: 'dict entry delimeter');
      items[key] = parseExpression();
    }

    if (environment.optimize &&
        items.entries
            .every((item) => item.key is Literal && item.value is Literal)) {
      return Literal(items.map((key, value) =>
          MapEntry((key as Literal).value, (value as Literal).value)));
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
      scanner.expect(nameReg, name: 'field identifier');
      return Field(scanner.lastMatch[1], expr);
    }

    if (scanner.scan(lBracketReg)) {
      final item = parseExpression();
      scanner.expect(rBracketReg);
      return Item(item, expr);
    }

    error('expected subscript expression');
  }

  Call parseCall({Expression expr}) {
    scanner.expect(lParenReg);

    final args = <Expression>[];
    final kwargs = <String, Expression>{};
    Expression argsDyn, kwargsDyn;

    var requireComma = false;

    while (!scanner.scan(rParenReg)) {
      if (requireComma) {
        scanner.expect(commaReg);
        if (scanner.scan(rParenReg)) break;
      }

      if (scanner.scan(RegExp(r'\*\*' + nameReg.pattern))) {
        kwargsDyn = Name(scanner.lastMatch[1]);
      } else if (scanner.scan(RegExp(r'\*' + nameReg.pattern))) {
        argsDyn = Name(scanner.lastMatch[1]);
      } else if (scanner.scan(RegExp(nameReg.pattern + assignReg.pattern)) &&
          argsDyn == null &&
          kwargsDyn == null) {
        final arg = scanner.lastMatch[1];
        final key = arg == 'default' ? '\$default' : arg;
        kwargs[key] = parseExpression();
      } else if (kwargs.isEmpty && argsDyn == null && kwargsDyn == null) {
        args.add(parseExpression());
      } else {
        error('message');
      }

      requireComma = true;
    }

    return Call(
      expr,
      args: args,
      kwargs: kwargs,
      argsDyn: argsDyn,
      kwargsDyn: kwargsDyn,
    );
  }

  Filter parseFilter({Expression expr, bool hasLeadingPipe = true}) {
    if (hasLeadingPipe) scanner.expect(pipeReg);

    do {
      scanner.expect(nameReg, name: 'filter name');

      final name = scanner.lastMatch[1];

      if (scanner.matches(lParenReg)) {
        final call = parseCall();
        expr = Filter(name, expr: expr, args: call.args, kwargs: call.kwargs);
      } else {
        expr = Filter(name, expr: expr);
      }
    } while (scanner.scan(pipeReg));

    return expr as Filter;
  }

  Expression parseTest(Expression expr) {
    final args = <Expression>[];
    final kwargs = <String, Expression>{};
    bool negated = false;

    scanner.scan(isReg);

    if (scanner.scan(notReg)) negated = true;

    scanner.expect(nameReg, name: 'test name');

    final name = scanner.lastMatch[1];

    if (scanner.matches(lParenReg)) {
      final call = parseCall();
      args.addAll(call.args);
      kwargs.addAll(call.kwargs);
    } else if (scanner.matches(inlineSpacePlusReg) &&
        !testAll(
            <Pattern>[elseReg, orReg, andReg, variableEndReg, blockEndReg])) {
      scanner.scan(spacePlusReg);

      final arg = parsePrimary();

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

class TemplateSyntaxError extends Error {
  TemplateSyntaxError(this.message, this.line, this.possition);

  final String message;
  final int line;
  final int possition;
}
