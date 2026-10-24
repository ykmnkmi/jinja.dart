import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/lexer.dart';
import 'package:jinja/src/nodes.dart';

final class Parser {
  factory(Environment environment, String source, {String? path}) {
    return Parser.fromTokens(environment, environment.lex(source), path: path);
  }

  new fromTokens(this.environment, Iterable<Token> tokens, {this.path})
    : reader = TokenReader(tokens),
      _endTokensStack = <List<(String, String?)>>[],
      _tagStack = <String>[];

  final Environment environment;

  final String? path;

  final TokenReader reader;

  final List<List<(String, String?)>> _endTokensStack;

  final List<String> _tagStack;

  Never fail(String message, [int? line]) {
    throw TemplateSyntaxError(message, line: line, path: path);
  }

  Never failUnknownTagEof(
    String? tag,
    List<List<(String, String?)>> endTokensStack, [
    int? line,
  ]) {
    var expected = <String>[];
    String? currentlyLooking;

    for (var tokens in endTokensStack) {
      expected.addAll(tokens.map<String>(describeTokenRecord));
    }

    if (endTokensStack.isNotEmpty) {
      currentlyLooking = endTokensStack.last
          .map<String>((token) => "'${describeTokenRecord(token)}'")
          .join(' or ');
    }

    var messages = <String>[];

    if (tag == null) {
      messages.add('Unexpected end of template.');
    } else {
      messages.add("Encountered unknown tag '$tag'.");
    }

    if (currentlyLooking != null) {
      if (tag != null && expected.contains(tag)) {
        messages
          ..add('You probably made a nesting mistake.')
          ..add(
            'Jinja is expecting this tag, but currently looking for '
            '$currentlyLooking.',
          );
      } else {
        messages.add(
          'Jinja was looking for the following tags: $currentlyLooking.',
        );
      }
    }

    if (_tagStack.isNotEmpty) {
      messages.add(
        "The innermost block that needs to be closed is '${_tagStack.last}'.",
      );
    }

    fail(messages.join(' '), line);
  }

  Never failUnknownTag(String tag, [int? line]) {
    failUnknownTagEof(tag, _endTokensStack, line);
  }

  Never failEof(List<(String, String?)> endTokens, [int? line]) {
    var stack = _endTokensStack.toList();
    stack.add(endTokens);
    failUnknownTagEof(null, stack, line);
  }

  bool isTupleEnd([List<(String, String?)>? extraEndRules]) {
    switch (reader.current.type) {
      case TokenType.variableEnd || TokenType.blockEnd || TokenType.rParen:
        return true;
      default:
        return extraEndRules != null && extraEndRules.isNotEmpty
            ? reader.current.matches(extraEndRules)
            : false;
    }
  }

  Node parseStatement() {
    var token = reader.current;

    if (token.type != TokenType.name) {
      fail('Tag name expected', token.line);
    }

    _tagStack.add(token.value);

    var popTag = true;

    try {
      switch (token.value) {
        case 'set':
          return parseSet();
        case 'for':
          return parseFor();
        case 'if':
          return parseIf();
        case 'with':
          return parseWith();
        case 'autoescape':
          return parseAutoEscape();
        case 'block':
          return parseBlock();
        case 'extends':
          return parseExtends();
        case 'include':
          return parseInclude();
        case 'import':
          return parseImport();
        case 'from':
          return parseFrom();
        case 'call':
          return parseCallBlock();
        case 'filter':
          return parseFilterBlock();
        case 'macro':
          return parseMacro();
        case 'print':
          return parsePrint();
        case 'do':
          return parseDo();
        case 'try':
          return parseTryCatch();
        default:
          _tagStack.removeLast();
          popTag = false;
          failUnknownTag(token.value, token.line);
      }
    } finally {
      if (popTag) {
        _tagStack.removeLast();
      }
    }
  }

  List<Node> parseStatements(
    List<(String, String?)> endTokens, [
    bool dropNeedle = false,
  ]) {
    reader.skipIf(TokenType.colon);
    reader.expect(TokenType.blockEnd);

    var nodes = subParse(endTokens: endTokens);

    if (reader.current.type == TokenType.eof) {
      failEof(endTokens);
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Statement parseSet() {
    const endSet = <(String, String)>[(TokenType.name, 'endset')];

    reader.expect(TokenType.name, 'set');

    var target = parseAssignTarget(withNameSpace: true);

    if (reader.skipIf(TokenType.assign)) {
      return Assign(target: target, value: parseTuple());
    }

    var filter = parseFilter(null) as Filter?;
    var nodes = parseStatements(endSet, true);
    return AssignBlock(target: target, filter: filter, nodes: nodes);
  }

  For parseFor() {
    const endIn = <(String, String)>[(TokenType.name, 'in')];
    const endFor = <(String, String)>[(TokenType.name, 'endfor')];

    const endForElse = <(String, String)>[
      (TokenType.name, 'endfor'),
      (TokenType.name, 'else'),
    ];

    reader.expect(TokenType.name, 'for');

    var target = parseAssignTarget(extraEndRules: endIn);
    reader.expect(TokenType.name, 'in');

    var iterable = parseTuple(withCondition: false);
    Expression? test;

    if (reader.skipIf(TokenType.name, 'if')) {
      test = parseExpression();
    }

    var recursive = reader.skipIf(TokenType.name, 'recursive');
    var nodes = parseStatements(endForElse);
    List<Node>? elseNodes;

    if (reader.next().match(TokenType.name, 'else')) {
      elseNodes = parseStatements(endFor, true);
    }

    return For(
      target: target,
      iterable: iterable,
      nodes: nodes,
      elseNodes: elseNodes,
      test: test,
      recursive: recursive,
    );
  }

  If parseIf() {
    const endIf = <(String, String)>[(TokenType.name, 'endif')];

    const endIfElseEndIf = <(String, String)>[
      (TokenType.name, 'elif'),
      (TokenType.name, 'else'),
      (TokenType.name, 'endif'),
    ];

    reader.expect(TokenType.name, 'if');

    var test = parseExpression(withCondition: false);
    var nodes = parseStatements(endIfElseEndIf);
    var root = If(test: test, nodes: nodes);
    var ifNodes = <If>[root];
    Token token;

    while (true) {
      token = reader.next();

      if (token.match(TokenType.name, 'elif')) {
        var test = parseTuple(withCondition: false);
        var nodes = parseStatements(endIfElseEndIf);
        var elif = If(test: test, nodes: nodes);
        ifNodes.add(elif);
        continue;
      }

      break;
    }

    List<Node>? elseNodes;

    if (token.match(TokenType.name, 'else')) {
      elseNodes = parseStatements(endIf, true);
    }

    return root.copyWith(
      elseIfNodes: ifNodes.length > 1 ? ifNodes.sublist(1) : null,
      elseNodes: elseNodes,
    );
  }

  With parseWith() {
    const endWith = <(String, String)>[(TokenType.name, 'endwith')];

    reader.expect(TokenType.name, 'with');

    var targets = <Expression>[];
    var values = <Expression>[];

    while (reader.current.type != TokenType.blockEnd) {
      if (targets.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      var target = parseAssignTarget(context: .parameter);
      targets.add(target);
      reader.expect(TokenType.assign);
      values.add(parseExpression());
    }

    var nodes = parseStatements(endWith, true);
    return With(targets: targets, values: values, nodes: nodes);
  }

  Never parseAutoEscape() {
    fail("'autoescape' is not supported.");
  }

  Block parseBlock() {
    const endBlock = <(String, String)>[(TokenType.name, 'endblock')];

    reader.expect(TokenType.name, 'block');

    var name = reader.expect(TokenType.name);
    var scoped = reader.skipIf(TokenType.name, 'scoped');
    var required = reader.skipIf(TokenType.name, 'required');

    if (reader.current.type == TokenType.sub) {
      fail('Use an underscore instead.');
    }

    var nodes = parseStatements(endBlock, true);

    if (required) {
      for (var node in nodes) {
        if (node is! Output ||
            node.nodes.any((data) => data is! Data || !data.isLeaf)) {
          fail('Required blocks can only contain comments or whitespace.');
        }
      }
    }

    reader.skipIf(TokenType.name, name.value);

    return Block(
      name: name.value,
      scoped: scoped,
      required: required,
      nodes: nodes,
    );
  }

  Extends parseExtends() {
    reader.expect(TokenType.name, 'extends');

    var template = parseExpression();
    return Extends(template: template);
  }

  bool parseImportContext({bool defaultValue = true}) {
    const keywords = <(String, String)>[
      (TokenType.name, 'with'),
      (TokenType.name, 'without'),
    ];

    var withContext = defaultValue;

    if (reader.current.matches(keywords) &&
        reader.look().match(TokenType.name, 'context')) {
      withContext = reader.current.value == 'with';
      reader.skip(2);
    }

    return withContext;
  }

  Include parseInclude() {
    reader.expect(TokenType.name, 'include');

    var template = parseExpression();

    var ignoreMissing =
        reader.current.match(TokenType.name, 'ignore') &&
        reader.look().match(TokenType.name, 'missing');

    if (ignoreMissing) {
      reader.skip(2);
    }

    var withContext = parseImportContext();

    return Include(
      template: template,
      ignoreMissing: ignoreMissing,
      withContext: withContext,
    );
  }

  Import parseImport() {
    reader.expect(TokenType.name, 'import');

    var template = parseExpression();
    reader.expect(TokenType.name, 'as');

    var target = parseAssignTarget(nameOnly: true) as Name;
    var withContext = parseImportContext(defaultValue: false);

    return Import(
      template: template,
      target: target.name,
      withContext: withContext,
    );
  }

  FromImport parseFrom() {
    reader.expect(TokenType.name, 'from');

    var template = parseExpression();
    reader.expect(TokenType.name, 'import');

    var names = <(String, String?)>[]; // target & alias
    var withContext = false;

    bool parseContext() {
      var value = reader.current.value;

      if (value != 'with' && value != 'without') {
        return false;
      }

      if (!reader.look().match(TokenType.name, 'context')) {
        return false;
      }

      withContext = value == 'with';
      reader.skip(2);
      return true;
    }

    while (true) {
      if (names.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.name) {
        if (parseContext()) {
          break;
        }

        var line = reader.current.line;
        var target = parseAssignTarget(nameOnly: true) as Name;

        if (target.name.startsWith('_')) {
          fail('Names starting with an underline can not be imported.', line);
        }

        if (reader.skipIf(TokenType.name, 'as')) {
          var alias = parseAssignTarget(nameOnly: true) as Name;
          names.add((target.name, alias.name));
        } else {
          names.add((target.name, null));
        }

        if (parseContext() || reader.current.type != TokenType.comma) {
          break;
        }
      } else {
        reader.expect(TokenType.name);
      }
    }

    return FromImport(
      template: template,
      names: names,
      withContext: withContext,
    );
  }

  // TODO(parser): check for duplicate arguments.
  void parseSignature(List<Expression> positional, List<Named> named) {
    var names = <Expression>[];
    var defaults = <Expression>[];
    reader.expect(TokenType.lParen);

    while (reader.current.type != TokenType.rParen) {
      if (names.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      var name = parseAssignTarget(nameOnly: true, context: .parameter) as Name;

      if (reader.skipIf(TokenType.assign)) {
        defaults.add(parseExpression());
      } else if (defaults.isNotEmpty) {
        fail('Non-default argument follows default argument.');
      }

      names.add(name);
    }

    reader.expect(TokenType.rParen);

    var length = names.length - defaults.length;
    positional.addAll(names.sublist(0, length));

    for (var i = 0; i < defaults.length; i++) {
      named.add(Named(argument: names[i + length], defaultValue: defaults[i]));
    }
  }

  CallBlock parseCallBlock() {
    const endCall = <(String, String)>[(TokenType.name, 'endcall')];

    reader.expect(TokenType.name, 'call');

    var line = reader.current.line;
    var positional = <Expression>[];
    var named = <Named>[];

    if (reader.current.type == TokenType.lParen) {
      parseSignature(positional, named);
    }

    var call = parseExpression();

    if (call is! Call) {
      fail('Expected call.', line);
    }

    var name = call.value;

    if (name is! Name) {
      fail('Expected call name.', line);
    }

    var nodes = parseStatements(endCall, true);

    return CallBlock(
      call: call,
      positional: positional,
      named: named,
      nodes: nodes,
    );
  }

  FilterBlock parseFilterBlock() {
    const endFilter = <(String, String)>[(TokenType.name, 'endfilter')];

    reader.expect(TokenType.name, 'filter');

    var line = reader.current.line;
    var filter = parseFilter(null, startInline: true);

    if (filter is! Filter) {
      fail('Expected filter.', line);
    }

    var nodes = parseStatements(endFilter, true);
    return FilterBlock(filter: filter, nodes: nodes);
  }

  Macro parseMacro() {
    const endMacro = <(String, String)>[(TokenType.name, 'endmacro')];

    reader.expect(TokenType.name, 'macro');

    var name = parseAssignTarget() as Name;

    var positional = <Expression>[];
    var named = <Named>[];
    parseSignature(positional, named);

    var nodes = parseStatements(endMacro, true);

    return Macro(
      name: name.name,
      positional: positional,
      named: named,
      nodes: nodes,
    );
  }

  Output parsePrint() {
    reader.expect(TokenType.name, 'print');

    var nodes = <Node>[];

    while (reader.current.type != TokenType.blockEnd) {
      if (nodes.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      nodes.add(parseExpression());
    }

    return Output(nodes: nodes);
  }

  Do parseDo() {
    reader.expect(TokenType.name, 'do');

    var expressions = <Expression>[];

    while (reader.current.type != TokenType.blockEnd) {
      if (expressions.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      expressions.add(parseExpression());
    }

    return Do(expressions: expressions);
  }

  Node parseTryCatch() {
    const endTry = <(String, String)>[(TokenType.name, 'catch')];
    const endTryCatch = <(String, String)>[(TokenType.name, 'endtry')];

    reader.expect(TokenType.name, 'try');

    var nodes = parseStatements(endTry);
    reader.expect(TokenType.name, 'catch');

    Name? exception;

    if (reader.current.type == TokenType.name) {
      exception = parseAssignTarget(nameOnly: true) as Name;
    }

    var catchNodes = parseStatements(endTryCatch);
    reader.expect(TokenType.name, 'endtry');
    return TryCatch(nodes: nodes, exception: exception, catchNodes: catchNodes);
  }

  Expression parseAssignTarget({
    bool withTuple = true,
    bool nameOnly = false,
    List<(String, String)>? extraEndRules,
    bool withNameSpace = false,
    AssignContext context = .store,
  }) {
    var line = reader.current.line;
    Expression target;

    if (nameOnly) {
      var token = reader.expect(TokenType.name);
      target = Name(name: token.value, context: context);
    } else {
      if (withTuple) {
        target = parseTuple(
          simplified: true,
          extraEndRules: extraEndRules,
          withNameSpace: withNameSpace,
          context: context,
        );
      } else {
        target = parsePrimary(withNameSpace: withNameSpace, context: context);
      }
    }

    if (!target.canAssign) {
      fail("Can't assign to $target.", line);
    }

    return target;
  }

  Expression parseExpression({bool withCondition = true}) {
    if (withCondition) {
      return parseCondition();
    }

    return parseOr();
  }

  Expression parseCondition() {
    var expression = parseOr();

    // Handle ternary operator: condition ? trueValue : falseValue
    if (reader.skipIf(TokenType.question)) {
      var trueValue = parseCondition();
      reader.expect(TokenType.colon);

      return Condition(
        test: expression,
        trueValue: trueValue,
        falseValue: parseCondition(),
      );
    }

    // Handle if-else syntax: trueValue if condition else falseValue
    while (reader.skipIf(TokenType.name, 'if')) {
      var condition = parseOr();

      if (reader.skipIf(TokenType.name, 'else')) {
        expression = Condition(
          test: condition,
          trueValue: expression,
          falseValue: parseCondition(),
        );
      } else {
        expression = Condition(test: condition, trueValue: expression);
      }
    }

    return expression;
  }

  Expression parseOr() {
    var value = parseAnd();

    while (reader.skipIf(TokenType.name, 'or') ||
        reader.skipIf(TokenType.nullCoalesce)) {
      value = Logical(operator: .or, left: value, right: parseAnd());
    }

    return value;
  }

  Expression parseAnd() {
    var value = parseNot();

    while (reader.skipIf(TokenType.name, 'and')) {
      value = Logical(operator: .and, left: value, right: parseNot());
    }

    return value;
  }

  Expression parseNot() {
    if (reader.current.match(TokenType.name, 'not')) {
      reader.next();
      return Unary(operator: .not, value: parseNot());
    }

    return parseCompare();
  }

  Expression parseCompare() {
    const operators = <String>{
      TokenType.eq,
      TokenType.ne,
      TokenType.lt,
      TokenType.ltEq,
      TokenType.gt,
      TokenType.gtEq,
    };

    var value = parseMath1();
    var operands = <Operand>[];

    while (true) {
      CompareOperator operator;

      if (operators.contains(reader.current.type)) {
        var symbol = reader.next();
        operator = .parse(symbol.type);
      } else if (reader.skipIf(TokenType.name, 'in')) {
        operator = .contains;
      } else if (reader.current.match(TokenType.name, 'not') &&
          reader.look().match(TokenType.name, 'in')) {
        reader.skip(2);
        operator = .notContains;
      } else {
        break;
      }

      operands.add(Operand(operator: operator, value: parseMath1()));
    }

    if (operands.isEmpty) {
      return value;
    }

    return Compare(value: value, operands: operands);
  }

  Expression parseMath1() {
    var value = parseConcat();

    outer:
    while (true) {
      ScalarOperator operator;

      switch (reader.current.type) {
        case TokenType.add:
          reader.next();
          operator = .plus;
        case TokenType.sub:
          reader.next();
          operator = .minus;
        default:
          break outer;
      }

      value = Scalar(operator: operator, left: value, right: parseConcat());
    }

    return value;
  }

  Expression parseConcat() {
    var values = <Expression>[parseMath2()];

    while (reader.current.type == TokenType.tilde) {
      reader.next();
      values.add(parseMath2());
    }

    if (values.length == 1) {
      return values[0];
    }

    return Concat(values: values);
  }

  Expression parseMath2() {
    var value = parsePow();

    outer:
    while (true) {
      ScalarOperator operator;

      switch (reader.current.type) {
        case TokenType.mul:
          reader.next();
          operator = .multiple;
        case TokenType.div:
          reader.next();
          operator = .division;
        case TokenType.floorDiv:
          reader.next();
          operator = .floorDivision;
        case TokenType.mod:
          reader.next();
          operator = .module;
        default:
          break outer;
      }

      value = Scalar(operator: operator, left: value, right: parsePow());
    }

    return value;
  }

  Expression parsePow() {
    var value = parseUnary();

    while (reader.current.type == TokenType.pow) {
      reader.next();
      value = Scalar(operator: .power, left: value, right: parseUnary());
    }

    return value;
  }

  Expression parseUnary({bool withFilter = true}) {
    Expression value;

    switch (reader.current.type) {
      case TokenType.add:
        reader.next();
        value = Unary(operator: .plus, value: parseUnary(withFilter: false));
      case TokenType.sub:
        reader.next();
        value = Unary(operator: .minus, value: parseUnary(withFilter: false));
      default:
        value = parsePrimary();
    }

    value = parsePostfix(value);

    if (withFilter) {
      value = parseFilterExpression(value);
    }

    return value;
  }

  Expression parsePrimary({
    bool withNameSpace = false,
    AssignContext context = .load,
  }) {
    var token = reader.current;
    Expression expression;

    switch (token.type) {
      case TokenType.name:
        reader.next();

        if (token.value case 'null' || 'none' || 'None') {
          expression = const Constant(value: null);
        } else if (token.value case 'true' || 'True') {
          expression = const Constant(value: true);
        } else if (token.value case 'false' || 'False') {
          expression = const Constant(value: false);
        } else if (withNameSpace && reader.current.type == TokenType.dot) {
          reader.next();

          var attribute = reader.expect(TokenType.name);
          expression = NsRef(name: token.value, attribute: attribute.value);
        } else {
          expression = Name(name: token.value, context: context);
        }

      case TokenType.string:
        reader.next();

        var buffer = StringBuffer(token.value);

        while (reader.current.type == TokenType.string) {
          buffer.write(reader.current.value);
          reader.next();
        }

        var value = buffer.toString();
        // TODO(parser): replace all escaped characters.
        value = value.replaceAll(r'\\r', '\r').replaceAll(r'\\n', '\n');
        expression = Constant(value: value);
      case TokenType.integer || TokenType.float:
        reader.next();
        expression = Constant(value: num.parse(token.value));
      case TokenType.lParen:
        reader.next();

        expression = parseTuple(
          simplified: context != .load,
          explicitParentheses: true,
          withNameSpace: withNameSpace,
          context: context,
        );

        reader.expect(TokenType.rParen);
      case TokenType.lBracket:
        expression = parseList();
      case TokenType.lBrace:
        expression = parseDict();
      default:
        fail('Unexpected ${describeToken(token)}.', token.line);
    }

    return expression;
  }

  Expression parseTuple({
    bool simplified = false,
    bool withCondition = true,
    List<(String, String)>? extraEndRules,
    bool explicitParentheses = false,
    bool withNameSpace = false,
    AssignContext context = .load,
  }) {
    Expression Function() parse;

    if (simplified) {
      parse = () {
        return parsePrimary(withNameSpace: withNameSpace, context: context);
      };
    } else {
      parse = () => parseExpression(withCondition: withCondition);
    }

    var values = <Expression>[];
    var isTuple = false;

    while (true) {
      if (values.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (isTupleEnd(extraEndRules)) {
        break;
      }

      values.add(parse());

      if (reader.current.type == TokenType.comma) {
        isTuple = true;
      } else {
        break;
      }
    }

    if (!isTuple) {
      if (values.isNotEmpty) {
        return values.first;
      }

      if (!explicitParentheses) {
        fail('Expected an expression, got ${describeToken(reader.current)}.');
      }
    }

    return Tuple(values: values);
  }

  Expression parseList() {
    reader.expect(TokenType.lBracket);

    var values = <Expression>[];

    while (reader.current.type != TokenType.rBracket) {
      if (values.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBracket) {
        break;
      }

      values.add(parseExpression());
    }

    reader.expect(TokenType.rBracket);
    return Array(values: values);
  }

  Expression parseDict() {
    reader.expect(TokenType.lBrace);

    var pairs = <Pair>[];

    while (reader.current.type != TokenType.rBrace) {
      if (pairs.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBrace) {
        break;
      }

      var key = parseExpression();
      reader.expect(TokenType.colon);

      var value = parseExpression();
      pairs.add(Pair(key: key, value: value));
    }

    reader.expect(TokenType.rBrace);
    return Dict(pairs: pairs);
  }

  Expression parsePostfix(Expression expression) {
    while (true) {
      var type = reader.current.type;

      if (type case TokenType.dot || TokenType.lBracket) {
        expression = parseSubscript(expression);
      } else if (type == TokenType.lParen) {
        expression = parseCall(expression);
      } else {
        break;
      }
    }

    return expression;
  }

  // TODO(parser): check if filters and tests exist, else throw TemplateAssertionError
  Expression parseFilterExpression(Expression expression) {
    while (true) {
      if (reader.current.type == TokenType.pipe) {
        var filter = parseFilter(expression);

        if (filter is! Filter) {
          fail('Expected filter.');
        }

        expression = filter;
      } else if (reader.current.match(TokenType.name, 'is')) {
        expression = parseTest(expression);
      } else if (reader.current.type == TokenType.lParen) {
        expression = parseCall(expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(Expression value) {
    var token = reader.next();

    if (token.type == TokenType.dot) {
      var attribute = reader.next();

      if (attribute.type == TokenType.name) {
        return Attribute(attribute: attribute.value, value: value);
      }

      if (attribute.type != TokenType.integer) {
        fail('Expected name or number.', attribute.line);
      }

      var key = Constant(value: int.parse(attribute.value));
      return Item(key: key, value: value);
    }

    if (token.type == TokenType.lBracket) {
      var values = <Expression>[];

      while (reader.current.type != TokenType.rBracket) {
        if (values.isNotEmpty) {
          reader.expect(TokenType.comma);
        }

        values.add(parseSubscribed());
      }

      reader.expect(TokenType.rBracket);

      Expression key;

      if (values.length == 1) {
        key = values[0];
      } else {
        key = Tuple(values: values);
      }

      return Item(key: key, value: value);
    }

    fail('Expected subscript expression.', token.line);
  }

  // TODO(parser): handle comma in slice.
  Expression parseSubscribed() {
    Expression? start;

    if (reader.current.type != TokenType.colon) {
      start = parseExpression();

      if (reader.current.type != TokenType.colon) {
        return start;
      }
    }

    reader.next();

    Expression? stop;

    if (reader.current.type != TokenType.rBracket &&
        reader.current.type != TokenType.comma) {
      stop = parseExpression();
    }

    if (reader.current.type == TokenType.colon) {
      reader.next();

      Expression? step;

      if (reader.current.type != TokenType.rBracket &&
          reader.current.type != TokenType.comma) {
        step = parseExpression();
      }

      return Slice(start: start, stop: stop, step: step);
    }

    return Slice(start: start, stop: stop);
  }

  Calling parseCalling() {
    var token = reader.expect(TokenType.lParen);
    var arguments = <Expression>[];
    var keywords = <Keyword>[];
    var requireComma = false;

    while (reader.current.type != TokenType.rParen) {
      if (requireComma) {
        reader.expect(TokenType.comma);

        if (reader.current.type == TokenType.rParen) {
          break;
        }
      }

      if (reader.current.type == TokenType.mul ||
          reader.current.type == TokenType.pow) {
        fail('Dynamic arguments are not supported.');
      }

      if (reader.current.type == TokenType.name &&
          reader.look().type == TokenType.assign) {
        var key = reader.current.value;
        reader.skip(2);

        var value = parseExpression();

        if (key == 'default') {
          // `default` is a Dart keyword, use `defaultValue` instead.
          key = 'defaultValue';
        }

        keywords.add(Keyword(key: key, value: value));
      } else {
        if (keywords.isNotEmpty) {
          fail('Invalid syntax for function call expression.', token.line);
        }

        arguments.add(parseExpression());
      }

      requireComma = true;
    }

    reader.expect(TokenType.rParen);
    return Calling(arguments: arguments, keywords: keywords);
  }

  Call parseCall(Expression expression) {
    return Call(value: expression, calling: parseCalling());
  }

  Expression? parseFilter(Expression? expression, {bool startInline = false}) {
    while (reader.current.type == TokenType.pipe || startInline) {
      if (!startInline) {
        reader.next();
      }

      var token = reader.expect(TokenType.name);
      var name = token.value;

      while (reader.current.type == TokenType.dot) {
        reader.next();
        token = reader.expect(TokenType.name);
        name += '.${token.value}';
      }

      Calling calling;

      if (reader.current.type == TokenType.lParen) {
        calling = parseCalling();
      } else {
        calling = const Calling();
      }

      expression = Filter(name: name, expression: expression, calling: calling);
      startInline = false;
    }

    return expression;
  }

  Expression parseTest(Expression expression) {
    const allow = <(String,)>{
      (TokenType.name,),
      (TokenType.string,),
      (TokenType.integer,),
      (TokenType.float,),
      (TokenType.lBracket,),
      (TokenType.lBrace,),
    };

    const deny = <(String, String)>[
      (TokenType.name, 'else'),
      (TokenType.name, 'or'),
      (TokenType.name, 'and'),
    ];

    reader.expect(TokenType.name, 'is');

    var negated = reader.skipIf(TokenType.name, 'not');

    var token = reader.expect(TokenType.name);
    var name = token.value;

    while (reader.skipIf(TokenType.dot)) {
      token = reader.expect(TokenType.name);
      name += '.${token.value}';
    }

    Calling calling;

    if (reader.current.type == TokenType.lParen) {
      calling = parseCalling();
    } else if (reader.current.matches(allow) && !reader.current.matches(deny)) {
      if (reader.current.match(TokenType.name, 'is')) {
        fail('You cannot chain multiple tests with is.');
      }

      calling = Calling(arguments: <Expression>[parsePostfix(parsePrimary())]);
    } else {
      calling = Calling();
    }

    expression = Test(name: name, expression: expression, calling: calling);

    if (negated) {
      expression = Unary(operator: .not, value: expression);
    }

    return expression;
  }

  List<Node> subParse({List<(String, String?)>? endTokens}) {
    var nodes = <Node>[];
    var dataBuffer = <Node>[];

    if (endTokens != null) {
      _endTokensStack.add(endTokens);
    }

    void flushData() {
      if (dataBuffer.isNotEmpty) {
        nodes.add(Output(nodes: dataBuffer));
        dataBuffer = <Node>[];
      }
    }

    try {
      while (reader.current.type != TokenType.eof) {
        var token = reader.current;

        if (token.type == TokenType.data) {
          if (token.value.isNotEmpty) {
            dataBuffer.add(Data(data: token.value));
          }

          reader.next();
        } else if (token.type == TokenType.variableBegin) {
          reader.next();
          dataBuffer.add(parseTuple());
          reader.expect(TokenType.variableEnd);
        } else if (token.type == TokenType.blockBegin) {
          flushData();
          reader.next();

          if (endTokens != null && reader.current.matches(endTokens)) {
            return nodes;
          }

          var node = parseStatement();
          nodes.add(node);
          reader.expect(TokenType.blockEnd);
        } else {
          assert(false, 'Internal parsing error.');
        }
      }

      flushData();
    } finally {
      if (endTokens != null) {
        _endTokensStack.removeLast();
      }
    }

    return nodes;
  }

  /// Parse whole template into [TemplateNode] node.
  TemplateNode parse() {
    return TemplateNode(nodes: subParse());
  }
}
