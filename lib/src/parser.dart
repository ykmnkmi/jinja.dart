import 'dart:async';

import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'nodes.dart';

typedef TemplateModifier = void Function(Template template);

class Parser {
  static RegExp getOpenReg(String rule, [bool leftStripBlocks = false]) {
    rule = RegExp.escape(rule);
    final strip = leftStripBlocks ? '(^[ \\t]*)$rule\\+|^[ \\t]*$rule|' : '';
    return RegExp('(?:\\s*$rule\\-|$strip$rule\\+?)\\s*', multiLine: true);
  }

  static RegExp getEndReg(String rule, [bool trimBlocks = false]) {
    rule = RegExp.escape(rule);
    final trim = trimBlocks ? '\n?' : '';
    return RegExp('\\s*(?:\\-$rule\\s*|$rule$trim)', multiLine: true);
  }

  Parser(this.environment, String source, {this.path})
      : scanner = SpanScanner(source, sourceUrl: path),
        commentStartReg =
            getOpenReg(environment.commentStart, environment.leftStripBlocks),
        commentEndReg =
            getEndReg(environment.commentEnd, environment.trimBlocks),
        variableStartReg = getOpenReg(environment.variableStart),
        variableEndReg = getEndReg(environment.variableEnd),
        blockStartReg =
            getOpenReg(environment.blockStart, environment.leftStripBlocks),
        blockEndReg = getEndReg(environment.blockEnd, environment.trimBlocks),
        keywords = {'not', 'and', 'or', 'is', 'if', 'else'},
        extendsStatements = <ExtendsStatement>[],
        endRulesStack = <List<Pattern>>[],
        tagsStack = <String>[],
        _onParseNameController = StreamController<Name>.broadcast(sync: true),
        _templateModifiers = <TemplateModifier>[];

  final Environment environment;

  final String? path;

  final SpanScanner scanner;

  final RegExp blockStartReg;

  final RegExp blockEndReg;

  final RegExp variableStartReg;

  final RegExp variableEndReg;

  final RegExp commentStartReg;

  final RegExp commentEndReg;

  final Set<String> keywords;

  final List<ExtendsStatement> extendsStatements;

  final List<List<Pattern>> endRulesStack;

  final List<String> tagsStack;

  RegExp getEndRegFor(String rule, [bool withStart = false]) {
    if (withStart) {
      return RegExp(
          blockStartReg.pattern + RegExp.escape(rule) + blockEndReg.pattern,
          multiLine: true);
    }

    return RegExp(RegExp.escape(rule) + blockEndReg.pattern);
  }

  final StreamController<Name> _onParseNameController;

  final List<TemplateModifier> _templateModifiers;

  Stream<Name> get onParseName {
    return _onParseNameController.stream;
  }

  void _addTemplateModifier(TemplateModifier modifier) {
    _templateModifiers.add(modifier);
  }

  Never error(String message, [LineScannerState? state]) {
    throw TemplateSyntaxError(message,
        path: path,
        line: state?.line ?? scanner.state.line,
        column: state?.column ?? scanner.state.column);
  }

  String expected(Pattern pattern, {int match = 1, String? name}) {
    if (!scanner.scan(pattern)) {
      if (name == null) {
        if (pattern is RegExp) {
          final source = pattern.pattern;
          name = '/$source/';
        } else {
          name = '$pattern'.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
          name = '"$name"';
        }
      }

      error('$name expected');
    }

    return scanner.lastMatch![match]!;
  }

  void expect(Pattern pattern, {String? name}) {
    if (!scanner.scan(pattern)) {
      if (name == null) {
        if (pattern is RegExp) {
          final source = pattern.pattern;
          name = '/$source/';
        } else {
          name = '$pattern'.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
          name = '"$name"';
        }
      }

      error('$name expected');
    }

    return;
  }

  Template parse() {
    final body = parseBody();
    final template = Template.parsed(environment, body, path);

    for (final modifier in _templateModifiers) {
      modifier(template);
    }

    return template;
  }

  Node parseBody([List<Pattern> endRules = const <Pattern>[]]) {
    final nodes = subParse(endRules);
    return environment.optimize
        ? Interpolation.orNode(nodes)
        : Interpolation(nodes);
  }

  List<Node> subParse(List<Pattern> endRules) {
    final buffer = StringBuffer();
    final body = <Node>[];

    if (endRules.isNotEmpty) {
      endRulesStack.add(endRules);
    }

    final flush = () {
      if (buffer.isNotEmpty) {
        body.add(Text(buffer.toString()));
        buffer.clear();
      }
    };

    try {
      while (!scanner.isDone) {
        if (scanner.scan(commentStartReg)) {
          flush();

          while (!scanner.matches(commentEndReg)) {
            scanner.readChar();
          }

          expect(commentEndReg);
        } else if (scanner.scan(variableStartReg)) {
          flush();
          body.add(parseExpression());

          expect(variableEndReg);
        } else if (scanner.scan(blockStartReg)) {
          // TODO: *** lstrip: check of the block shadows body variable
          flush();

          if (scanner.lastMatch!.groupCount > 0 &&
              scanner.lastMatch![0]!.trimRight().endsWith('+')) {
            final spaces = scanner.lastMatch![1]!;

            if (spaces.isNotEmpty) {
              if (body.isNotEmpty && body.last is Text) {
                body.add(Text((body.removeLast() as Text).text + spaces));
              } else {
                body.add(Text(spaces));
              }
            }
          }

          if (endRules.isNotEmpty && testAll(endRules)) {
            return body;
          }

          body.add(parseStatement());
        } else {
          buffer.writeCharCode(scanner.readChar());
        }
      }

      flush();
    } finally {
      if (endRules.isNotEmpty) {
        endRulesStack.removeLast();
      }
    }

    return body;
  }

  bool testAll(List<Pattern> endRules) {
    for (final rule in endRules) {
      if (scanner.matches(rule)) {
        return true;
      }
    }

    return false;
  }

  Node parseStatement() {
    final tagName = expected(nameReg, name: 'statement tag');

    var popTag = true;
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
      }

      tagsStack.removeLast();
      popTag = false;

      error('unknown tag: $tagName');
    } finally {
      if (popTag) {
        tagsStack.removeLast();
      }
    }
  }

  // TODO: can't pass test with multiple `extended` elements
  ExtendsStatement parseExtends() {
    final path = parsePrimary();

    expect(blockEndReg);

    final extendsStatement = ExtendsStatement(path);
    extendsStatements.add(extendsStatement);
    final state = scanner.state;

    _addTemplateModifier((Template template) {
      final body = template.body;

      if (body is Interpolation) {
        final first = body.nodes.first;

        if (body.nodes.sublist(1).any((node) => node is ExtendsStatement)) {
          error('only one extends statement contains in template', state);
        }

        body.nodes
          ..clear()
          ..add(first);
      }
    });

    return extendsStatement;
  }

  BlockStatement parseBlock() {
    final blockEndReg = getEndRegFor('endblock');

    if (scanner.matches(this.blockEndReg)) {
      error('block name expected');
    }

    final name = expected(nameReg, name: 'block name');
    final scoped = scanner.scan(spacePlusReg) && scanner.scan('scoped');

    expect(this.blockEndReg);

    var hasSuper = false;
    final subscription = onParseName.listen((node) {
      if (node.name == 'super') {
        hasSuper = true;
      }
    });

    final body = parseBody([blockEndReg]);
    subscription.cancel();

    expect(blockEndReg);

    if (extendsStatements.isNotEmpty) {
      final block = ExtendedBlockStatement(name, body,
          path: path, scoped: scoped, hasSuper: hasSuper);

      for (final extendsStatement in extendsStatements) {
        extendsStatement.blocks.add(block);
      }

      return block;
    }

    final block = BlockStatement(name, body, path: path, scoped: scoped);

    _addTemplateModifier((template) {
      template.blocks[block.name] = block;
    });

    return block;
  }

  IncludeStatement parseInlcude() {
    final oneOrList = parsePrimary();
    var ignoreMissing = false;
    var withContext = true;

    if (scanner.scan(' ignore missing')) {
      ignoreMissing = true;
    }

    if (scanner.scan(' without context')) {
      withContext = false;
    }

    scanner.scan(' with context');

    expect(blockEndReg);

    return IncludeStatement(oneOrList,
        ignoreMissing: ignoreMissing, withContext: withContext);
  }

  ForStatement parseFor() {
    final elseReg = getEndRegFor('else');
    final forEndReg = getEndRegFor('endfor');
    final targets = parseAssignTarget();

    expect(spacePlusReg);
    expect('in');
    expect(spacePlusReg);

    final iterable = parseExpression(withCondition: false);
    Expression? filter;

    if (scanner.scan(ifReg)) {
      filter = parseExpression(withCondition: false);
    }

    expect(blockEndReg);

    final body = parseBody([elseReg, forEndReg]);

    Node? orElse;

    if (scanner.scan(elseReg)) {
      orElse = parseBody([forEndReg]);
    }

    expect(forEndReg);

    return filter != null
        ? ForStatementWithFilter(targets, iterable, body, filter,
            orElse: orElse)
        : ForStatement(targets, iterable, body, orElse: orElse);
  }

  IfStatement parseIf() {
    final elseReg = getEndRegFor('else');
    final ifEndReg = getEndRegFor('endif');
    final pairs = <Expression, Node>{};
    Node? orElse;

    while (true) {
      if (scanner.matches(blockEndReg)) {
        error('expect statement body');
      }

      final condition = parseExpression();

      expect(blockEndReg);

      final body = parseBody(['elif', elseReg, ifEndReg]);

      if (scanner.scan('elif')) {
        scanner.scan(spaceReg);
        pairs[condition] = body;
        continue;
      } else if (scanner.scan(elseReg)) {
        pairs[condition] = body;
        orElse = parseBody([ifEndReg]);
      } else {
        pairs[condition] = body;
      }

      break;
    }

    expect(ifEndReg);

    return IfStatement(pairs, orElse);
  }

  SetStatement parseSet() {
    final setEndReg = getEndRegFor('endset');
    final target = expected(nameReg);
    late String field;

    if (scanner.scan(dotReg) && scanner.scan(nameReg)) {
      field = scanner.lastMatch![1]!;
    }

    if (scanner.scan(assignReg)) {
      if (scanner.matches(blockEndReg)) {
        error('expression expected');
      }

      final value = parseExpression(withCondition: false);

      expect(blockEndReg);

      return SetInlineStatement(target, value, field: field);
    }

    final filters = <Filter>[];

    while (scanner.scan(pipeReg)) {
      final filter = parseFilter(hasLeadingPipe: false);

      // TODO: check
      // if (filter == null) {
      //   error('filter expected but got ${filter.runtimeType}');
      // }

      filters.add(filter);
    }

    expect(blockEndReg);

    var body = parseBody([setEndReg]);

    expect(setEndReg);

    if (filters.isNotEmpty) {
      body = FilterBlockStatement(filters, body);
    }

    return SetBlockStatement(target, body, field: field);
  }

  RawStatement parseRaw() {
    final endRawReg = getEndRegFor('endraw', true);

    expect(getEndReg(environment.blockEnd));

    final start = scanner.state;
    var end = start;

    while (!scanner.isDone && !scanner.scan(endRawReg)) {
      scanner.readChar();
      end = scanner.state;
    }

    return RawStatement(scanner.substring(start.position, end.position));
  }

  FilterBlockStatement parseFilterBlock() {
    final filterEndReg = getEndRegFor('endfilter');

    if (scanner.matches(blockEndReg)) {
      error('filter expected');
    }

    final filters = <Filter>[];

    while (scanner.scan(pipeReg)) {
      final filter = parseFilter(hasLeadingPipe: false);

      // TODO: check
      // if (filter == null) {
      //   error('filter expected but got ${filter.runtimeType}');
      // }

      filters.add(filter);
    }

    expect(blockEndReg);

    final body = parseBody([filterEndReg]);

    expect(filterEndReg);

    return FilterBlockStatement(filters, body);
  }

  List<String> parseAssignTarget(
      {bool withTuple = true, List<Pattern> extraEndRules = const []}) {
    late CanAssign target;

    if (withTuple) {
      final tuple =
          parseTuple(simplified: true, extraEndRules: extraEndRules) as dynamic;

      if (tuple is CanAssign) {
        target = tuple;
      } else {
        error('can\'t assign to "$tuple"');
      }
    } else {
      target = Name(expected(nameReg));
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
    var expr = parseOr();

    while (scanner.scan(ifReg)) {
      final testExpr = parseOr();
      late Test test;
      Expression? elseExpr;

      if (testExpr is Test) {
        test = testExpr;
      } else {
        test = Test('defined', expr: testExpr);
      }

      if (scanner.scan(elseReg)) {
        elseExpr = parseCondition();
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
      late String op;

      if (scanner.scan(compareReg)) {
        op = scanner.lastMatch![1]!;
      } else if (scanner.scan(inReg)) {
        op = 'in';
      } else if (scanner.scan(notInReg)) {
        op = 'notin';
      } else {
        break;
      }

      final right = parseMath1();

      // TODO: check
      // if (right == null) {
      //   error('Expected math expression');
      // }

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
          left = Test('in', expr: left, positional: [right]);
          break;
        case 'notin':
          left = Not(Test('in', expr: left, positional: [right]));
      }
    }

    return left;
  }

  Expression parseMath1() {
    var left = parseConcat();

    while (!testAll([variableEndReg, blockEndReg]) && scanner.scan(math1Reg)) {
      final op = scanner.lastMatch![1]!;
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

    while (!testAll([variableEndReg, blockEndReg]) && scanner.scan(tildaReg)) {
      args.add(parseMath2());
    }

    if (args.length == 1) {
      return args[0];
    }

    return Concat(args);
  }

  Expression parseMath2() {
    var left = parsePow();

    while (!testAll([variableEndReg, blockEndReg]) && scanner.scan(math2Reg)) {
      final op = scanner.lastMatch![1]!;
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
    var left = parseUnary(withFilter: true);

    while (scanner.scan(powReg)) {
      left = Pow(left, parseUnary(withFilter: true));
    }

    return left;
  }

  Expression parseUnary({bool withFilter = false}) {
    late Expression expr;

    if (scanner.scan(unaryReg)) {
      switch (scanner.lastMatch![1]!) {
        case '-':
          expr = Neg(parseUnary());
          break;
        case '+':
          expr = parseUnary();
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
    late Expression expr;

    if (scanner.scan('false')) {
      expr = Literal(false);
    } else if (scanner.scan('true')) {
      expr = Literal(true);
    } else if (scanner.scan('none')) {
      expr = Literal(null);
    } else if (scanner.scan(nameReg)) {
      final name = scanner.lastMatch![1]!;
      final nameExpr = Name(name);
      _onParseNameController.add(nameExpr);
      expr = nameExpr;
    } else if (scanner.scan(stringStartReg)) {
      late String body;

      switch (scanner.lastMatch![1]!) {
        case '"':
          body = expected(stringContentDQReg,
              name: 'string content and double quote');
          break;
        case '\'':
          body = expected(stringContentSQReg,
              name: 'string content and single quote');
      }

      expr = Literal(body);
    } else if (scanner.scan(digitReg)) {
      final integer = scanner.lastMatch![1]!;

      if (scanner.scan(fractionalReg)) {
        expr = Literal(double.tryParse(integer + scanner.lastMatch![0]!));
      } else {
        expr = Literal(int.tryParse(integer));
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

  Expression parseTuple(
      {bool simplified = false,
      bool withCondition = true,
      List<Pattern> extraEndRules = const [],
      bool explicitParentheses = false}) {
    late Expression Function() $parse;

    if (simplified) {
      $parse = parsePrimary;
    } else if (withCondition) {
      $parse = parseExpression;
    } else {
      $parse = () => parseExpression(withCondition: true);
    }

    final args = <Expression>[];
    var isTuple = false;

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
      if (args.isNotEmpty) {
        return args.single;
      }

      if (!explicitParentheses) {
        error('expected an expression');
      }
    }

    return TupleExpression(args);
  }

  bool isTupleEnd([List<Pattern> extraEndRules = const []]) {
    if (testAll([variableEndReg, blockEndReg, rParenReg])) {
      return true;
    }

    if (extraEndRules.isNotEmpty) {
      return testAll(extraEndRules);
    }

    return false;
  }

  Expression parseList() {
    expect(lBracketReg);

    final items = <Expression>[];

    while (!scanner.scan(rBracketReg)) {
      if (items.isNotEmpty) {
        expect(commaReg);
      }

      if (scanner.scan(rBracketReg)) {
        break;
      }

      items.add(parseExpression());
    }

    if (environment.optimize && items.every((item) => item is Literal)) {
      return Literal(
          items.map((item) => (item as Literal).value).toList(growable: false));
    }

    return ListExpression(items);
  }

  Expression parseMap() {
    expect(lBraceReg);

    final items = <Expression, Expression>{};

    while (!scanner.scan(rBraceReg)) {
      if (items.isNotEmpty) {
        expect(commaReg);
      }

      final key = parseExpression();

      expect(colonReg, name: 'dict entry delimeter');

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
        expr = parseCall(expr);
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
        expr = parseCall(expr);
      } else {
        break;
      }
    }

    return expr;
  }

  Expression parseSubscript(Expression expr) {
    if (scanner.scan(dotReg)) {
      return Field(expr, expected(nameReg, name: 'field identifier'));
    }

    if (scanner.scan(lBracketReg)) {
      final item = parseExpression();

      expect(rBracketReg);

      return Item(expr, item);
    }

    error('expected subscript expression');
  }

  Call parseCall(Expression expr) {
    return Call(expr, parseCallArguments());
  }

  Arguments parseCallArguments({bool expectLParenReg = true}) {
    if (expectLParenReg) {
      expect(lParenReg);
    }

    final positional = <Expression>[];
    final named = <String, Expression>{};
    var requireComma = false;

    Expression? positionalExpr;
    Expression? namedExpr;

    while (!scanner.scan(rParenReg)) {
      if (requireComma) {
        expect(commaReg);

        if (scanner.scan(rParenReg)) {
          break;
        }
      }

      if (scanner.scan('**')) {
        namedExpr = parseExpression();
      } else if (scanner.scan('*')) {
        positionalExpr = parseExpression();
      } else if (scanner.scan(assignReg) &&
          positionalExpr == null &&
          namedExpr == null) {
        final arg = scanner.lastMatch![1]!;
        final key = arg == 'default' ? r'$default' : arg;
        named[key] = parseExpression();
      } else if (named.isEmpty && positionalExpr == null && namedExpr == null) {
        positional.add(parseExpression());
      } else {
        error('message');
      }

      requireComma = true;
    }

    return Arguments(
        positional: positional,
        named: named,
        positionalExpr: positionalExpr,
        namedExpr: namedExpr);
  }

  Filter parseFilter({Expression? expr, bool hasLeadingPipe = true}) {
    if (hasLeadingPipe) {
      expect(pipeReg);
    }

    if (expr != null) {
      do {
        expr = parseFilterBody(expr);
      } while (scanner.scan(pipeReg));
    } else {
      expr = parseFilterBody(expr);
    }

    return expr as Filter;
  }

  Expression? parseFilterBody(Expression? expr) {
    final name = expected(nameReg, name: 'filter name');

    if (scanner.matches(lParenReg)) {
      expect(lParenReg);

      final arguments = parseCallArguments();
      expr = Filter(name,
          expr: expr, positional: arguments.positional, named: arguments.named);
    } else {
      expr = Filter(name, expr: expr);
    }

    return expr;
  }

  Expression parseTest(Expression expr) {
    expect(isReg);

    final positional = <Expression>[];
    final named = <String, Expression>{};
    final negated = scanner.scan(notReg);

    final name = expected(nameReg, name: 'test name');

    if (scanner.matches(lParenReg)) {
      final arguments = parseCallArguments();
      positional.addAll(arguments.positional);
      named.addAll(arguments.named);
    } else if (scanner.matches(inlineSpacePlusReg) &&
        !testAll([elseReg, orReg, andReg, variableEndReg, blockEndReg])) {
      expect(spacePlusReg);

      final arg = parsePrimary();

      if (arg is Name) {
        if (!(const ['else', 'or', 'and']).contains(arg.name)) {
          if (arg.name == 'is') {
            error('can not chain multiple tests with is');
          }
        }
      }

      positional.add(arg);
    }

    expr = Test(name, expr: expr, positional: positional, named: named);
    return negated ? Not(expr) : expr;
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
  static final RegExp assignReg = RegExp(r'([a-zA-Z][a-zA-Z0-9]*)?\s*=\s*');
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
