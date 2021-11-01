import 'environment.dart';
import 'exceptions.dart';
import 'lexer.dart';
import 'nodes.dart';
import 'reader.dart';

class Parser {
  Parser(this.environment, {this.path})
      : endTokensStack = <List<String>>[],
        tagStack = <String>[],
        blocks = <String>{};

  final Environment environment;

  final String? path;

  final List<List<String>> endTokensStack;

  final List<String> tagStack;

  final Set<String> blocks;

  Never fail(String message, [int? line]) {
    throw TemplateSyntaxError(message, line: line, path: path);
  }

  Never failUnknownTagEof(String? name, List<List<String>> endTokensStack,
      [int? line]) {
    var expected = <String>[];
    String? currentlyLooking;

    for (var tokens in endTokensStack) {
      expected.addAll(tokens.map<String>(describeExpression));
    }

    if (endTokensStack.isNotEmpty) {
      currentlyLooking = endTokensStack.last
          .map<String>(describeExpression)
          .map<String>((token) => '\'$token\'')
          .join(' or ');
    }

    var message = name == null
        ? <String>['Unexpected end of template.']
        : <String>['Encountered unknown tag \'$name\'.'];

    if (currentlyLooking != null) {
      if (name != null && expected.contains(name)) {
        message.add(
            'You probably made a nesting mistake. Jinja is expecting this tag, but currently looking for $currentlyLooking.');
      } else {
        message.add(
            'Jinja was looking for the following tags: $currentlyLooking.');
      }
    }

    if (tagStack.isNotEmpty) {
      message.add(
          'The innermost block that needs to be closed is \'${tagStack.last}\'.');
    }

    fail(message.join(' '), line);
  }

  Never failUnknownTag(String name, [int? line]) {
    failUnknownTagEof(name, endTokensStack, line);
  }

  Never failEof(List<String> endTokens, [int? line]) {
    var stack = endTokensStack.toList();
    stack.add(endTokens);
    failUnknownTagEof(null, stack, line);
  }

  bool isTupleEnd(TokenReader reader, [List<String>? extraEndRules]) {
    switch (reader.current.type) {
      case 'variable_end':
      case 'block_end':
      case 'rparen':
        return true;
      default:
        if (extraEndRules != null && extraEndRules.isNotEmpty) {
          return reader.current.testAny(extraEndRules);
        }

        return false;
    }
  }

  T parseImportContext<T extends ImportContext>(TokenReader reader, T node,
      [bool defaultValue = true]) {
    if (reader.current.testAny(<String>['name:with', 'name:without']) &&
        reader.look().test('name', 'context')) {
      node.withContext = reader.current.value == 'with';
      reader.skip(2);
    } else {
      node.withContext = defaultValue;
    }

    return node;
  }

  Expression parseAssignTarget(TokenReader reader,
      {List<String>? extraEndRules,
      bool nameOnly = false,
      bool withNamespace = false,
      bool withTuple = true}) {
    var line = reader.current.line;
    Expression target;

    if (withNamespace && reader.look().test('dot')) {
      var namespace = reader.expect('name');
      reader.next(); // skip dot
      var attribute = reader.expect('name');

      target = NamespaceRef(namespace.value, attribute.value);
    } else if (nameOnly) {
      var name = reader.expect('name');

      target = Name(name.value, context: AssignContext.store);
    } else {
      if (withTuple) {
        target =
            parseTuple(reader, simplified: true, extraEndRules: extraEndRules);
      } else {
        target = parsePrimary(reader);
      }

      if (target is Assignable) {
        target.context = AssignContext.store;
      } else {
        fail('can\'t assign to ${target.runtimeType}', line);
      }
    }

    return target;
  }

  Node parseStatement(TokenReader reader) {
    var token = reader.current;

    if (!token.test('name')) {
      fail('tag name expected', token.line);
    }

    tagStack.add(token.value);
    var popTag = true;

    try {
      switch (token.value) {
        case 'extends':
          return parseExtends(reader);
        case 'for':
          return parseFor(reader);
        case 'if':
          return parseIf(reader);
        case 'filter':
          return parseFilterBlock(reader);
        case 'with':
          return parseWith(reader);
        case 'block':
          return parseBlock(reader);
        case 'include':
          return parseInclude(reader);
        case 'do':
          return parseDo(reader);
        case 'set':
          return parseAssign(reader);
        case 'autoescape':
          return parseAutoEscape(reader);
        default:
          tagStack.removeLast();
          popTag = false;
          failUnknownTag(token.value, token.line);
      }
    } finally {
      if (popTag) {
        tagStack.removeLast();
      }
    }
  }

  List<Node> parseStatements(TokenReader reader, List<String> endTokens,
      [bool dropNeedle = false]) {
    reader.skipIf('colon');
    reader.expect('block_end');
    var nodes = subParse(reader, endTokens: endTokens);

    if (reader.current.test('eof')) {
      failEof(endTokens);
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Extends parseExtends(TokenReader reader) {
    reader.expect('name', 'extends');
    var node = parsePrimary(reader);

    if (node is! Constant) {
      // TODO: update error
      fail('template name or path expected');
    }

    return Extends(node.value as String);
  }

  For parseFor(TokenReader reader) {
    reader.expect('name', 'for');
    var target = parseAssignTarget(reader, extraEndRules: <String>['name:in']);

    if (target is Name && target.name == 'loop') {
      fail('can\'t assign to special loop variable in for-loop target');
    }

    reader.expect('name', 'in');
    var iterable = parseTuple(reader, withCondition: false);
    Expression? test;

    if (reader.skipIf('name', 'if')) {
      test = parseExpression(reader);
    }

    var recursive = reader.skipIf('name', 'recursive');
    var nodes = parseStatements(reader, <String>['name:endfor', 'name:else']);
    var body = Output.orSingle(nodes);

    Node? orElse;

    if (reader.next().test('name', 'else')) {
      var nodes = parseStatements(reader, <String>['name:endfor'], true);
      orElse = Output.orSingle(nodes);
    }

    return For(target, iterable, body,
        orElse: orElse, test: test, recursive: recursive);
  }

  If parseIf(TokenReader reader) {
    reader.expect('name', 'if');
    var test = parseExpression(reader, false);
    var nodes = parseStatements(
        reader, <String>['name:elif', 'name:else', 'name:endif']);

    var root = If(test, Output.orSingle(nodes));
    var node = root;

    while (true) {
      var tag = reader.next();

      if (tag.test('name', 'elif')) {
        var test = parseTuple(reader, withCondition: false);
        var nodes = parseStatements(
            reader, <String>['name:elif', 'name:else', 'name:endif']);
        var next = If(test, Output.orSingle(nodes));
        node.orElse = next;
        node = next;
        continue;
      }

      if (tag.test('name', 'else')) {
        var nodes = parseStatements(reader, <String>['name:endif'], true);
        node.orElse = Output.orSingle(nodes);
      }

      break;
    }

    return root;
  }

  FilterBlock parseFilterBlock(TokenReader reader) {
    reader.expect('name', 'filter');
    var filters = parseFilters(reader, true);
    var nodes = parseStatements(reader, <String>['name:endfilter'], true);
    return FilterBlock(filters, Output.orSingle(nodes));
  }

  With parseWith(TokenReader reader) {
    reader.expect('name', 'with');
    var targets = <Expression>[];
    var values = <Expression>[];

    while (!reader.current.test('block_end')) {
      if (targets.isNotEmpty) {
        reader.expect('comma');
      }

      var target = parseAssignTarget(reader);
      (target as Assignable).context = AssignContext.parameter;
      targets.add(target);
      reader.expect('assign');
      values.add(parseExpression(reader));
    }

    var nodes = parseStatements(reader, <String>['name:endwith'], true);
    return With(targets, values, Output.orSingle(nodes));
  }

  Block parseBlock(TokenReader reader) {
    var token = reader.expect('name', 'block');
    var name = reader.expect('name');

    if (blocks.contains(name.value)) {
      fail('block \'${name.value}\' defined twice', reader.current.line);
    }

    var scoped = reader.skipIf('name', 'scoped');

    if (reader.current.test('sub')) {
      fail('use an underscore instead', reader.current.line);
    }

    var required = reader.skipIf('name', 'required');
    var nodes = parseStatements(reader, <String>['name:endblock'], true);

    if (required && nodes.any((node) => node is! Data || !node.isLeaf)) {
      throw TemplateSyntaxError(
          'required blocks can only contain comments or whitespace',
          line: token.line);
    }

    var maybeName = reader.current;

    if (maybeName.test('name')) {
      if (maybeName.value != name.value) {
        // TODO: update error
        fail('\'${name.value}\' expected, got ${maybeName.value}');
      }

      reader.next();
    }

    return Block(name.value, scoped, required, Output.orSingle(nodes));
  }

  Include parseInclude(TokenReader reader) {
    reader.expect('name', 'include');
    var name = reader.expect('string');
    var node = Include(name.value);
    return parseImportContext<Include>(reader, node, true);
  }

  Do parseDo(TokenReader reader) {
    reader.expect('name', 'do');
    return Do(parseTuple(reader));
  }

  Statement parseAssign(TokenReader reader) {
    reader.expect('name', 'set');
    var target = parseAssignTarget(reader, withNamespace: true);

    if (reader.skipIf('assign')) {
      var expression = parseTuple(reader);
      return Assign(target, expression);
    }

    var filters = parseFilters(reader);
    var nodes = parseStatements(reader, <String>['name:endset'], true);
    return AssignBlock(target, Output.orSingle(nodes), filters);
  }

  Scope parseAutoEscape(TokenReader reader) {
    reader.expect('name', 'autoescape');
    var escape = parseExpression(reader);
    var body = parseStatements(reader, <String>['name:endautoescape'], true);
    var options = <String, Expression>{'autoEscape': escape};
    var modifier = ScopedContextModifier(options, Output.orSingle(body));
    return Scope(modifier);
  }

  Expression parseExpression(TokenReader reader, [bool withCondition = true]) {
    if (withCondition) {
      return parseCondition(reader);
    }

    return parseOr(reader);
  }

  Expression parseCondition(TokenReader reader, [bool withCondExpr = true]) {
    var whenTrue = parseOr(reader);

    while (reader.skipIf('name', 'if')) {
      var condition = parseOr(reader);

      if (reader.skipIf('name', 'else')) {
        var whenFalse = parseCondition(reader);
        whenTrue = Condition(condition, whenTrue, whenFalse);
      } else {
        whenTrue = Condition(condition, whenTrue);
      }
    }

    return whenTrue;
  }

  Expression parseOr(TokenReader reader) {
    var expression = parseAnd(reader);

    while (reader.skipIf('name', 'or')) {
      expression = Binary('or', expression, parseAnd(reader));
    }

    return expression;
  }

  Expression parseAnd(TokenReader reader) {
    var expression = parseNot(reader);

    while (reader.skipIf('name', 'and')) {
      expression = Binary('and', expression, parseNot(reader));
    }

    return expression;
  }

  Expression parseNot(TokenReader reader) {
    if (reader.current.test('name', 'not')) {
      reader.next();
      return Unary('not', parseNot(reader));
    }

    return parseCompare(reader);
  }

  Expression parseCompare(TokenReader reader) {
    var expression = parseMath1(reader);
    var operands = <Operand>[];

    while (true) {
      if (reader.current.testAny(['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'])) {
        var type = reader.current.type;
        reader.next();
        operands.add(Operand(type, parseMath1(reader)));
      } else if (reader.skipIf('name', 'in')) {
        operands.add(Operand('in', parseMath1(reader)));
      } else if (reader.current.test('name', 'not') &&
          reader.look().test('name', 'in')) {
        reader.skip(2);
        operands.add(Operand('notin', parseMath1(reader)));
      } else {
        break;
      }
    }

    if (operands.isEmpty) {
      return expression;
    }

    return Compare(expression, operands);
  }

  Expression parseMath1(TokenReader reader) {
    var expression = parseConcat(reader);

    outer:
    while (true) {
      switch (reader.current.type) {
        case 'add':
          reader.next();
          expression = Binary('+', expression, parseConcat(reader));
          break;
        case 'sub':
          reader.next();
          expression = Binary('-', expression, parseConcat(reader));
          break;
        default:
          break outer;
      }
    }

    return expression;
  }

  Expression parseConcat(TokenReader reader) {
    var expressions = <Expression>[parseMath2(reader)];

    while (reader.current.test('tilde')) {
      reader.next();
      expressions.add(parseMath2(reader));
    }

    if (expressions.length == 1) {
      return expressions[0];
    }

    return Concat(expressions);
  }

  Expression parseMath2(TokenReader reader) {
    var expression = parsePow(reader);

    outer:
    while (true) {
      switch (reader.current.type) {
        case 'mul':
          reader.next();
          expression = Binary('*', expression, parsePow(reader));
          break;
        case 'div':
          reader.next();
          expression = Binary('/', expression, parsePow(reader));
          break;
        case 'floordiv':
          reader.next();
          expression = Binary('//', expression, parsePow(reader));
          break;
        case 'mod':
          reader.next();
          expression = Binary('%', expression, parsePow(reader));
          break;
        default:
          break outer;
      }
    }

    return expression;
  }

  Expression parsePow(TokenReader reader) {
    var expression = parseUnary(reader);

    while (reader.current.test('pow')) {
      reader.next();
      expression = Binary('**', expression, parseUnary(reader));
    }

    return expression;
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression expression;

    switch (reader.current.type) {
      case 'add':
        reader.next();
        expression = parseUnary(reader, withFilter: false);
        expression = Unary('+', expression);
        break;
      case 'sub':
        reader.next();
        expression = parseUnary(reader, withFilter: false);
        expression = Unary('-', expression);
        break;
      default:
        expression = parsePrimary(reader);
    }

    expression = parsePostfix(reader, expression);

    if (withFilter) {
      expression = parseFilterExpression(reader, expression);
    }

    return expression;
  }

  Expression parsePrimary(TokenReader reader) {
    var current = reader.current;
    Expression expression;

    switch (current.type) {
      case 'name':
        switch (current.value) {
          case 'False':
          case 'false':
            expression = Constant(false);
            break;
          case 'True':
          case 'true':
            expression = Constant(true);
            break;
          case 'None':
          case 'none':
          case 'null':
            expression = Constant(null);
            break;
          default:
            expression = Name(current.value);
        }

        reader.next();
        break;
      case 'string':
        var buffer = StringBuffer(current.value);
        reader.next();

        while (reader.current.test('string')) {
          buffer.write(reader.current.value);
          reader.next();
        }

        expression = Constant(
            '$buffer'.replaceAll(r'\\r', '\r').replaceAll(r'\\n', '\n'));
        break;
      case 'integer':
      case 'float':
        expression = Constant(num.parse(current.value));
        reader.next();
        break;
      case 'lparen':
        reader.next();
        expression = parseTuple(reader, explicitParentheses: true);
        reader.expect('rparen');
        break;
      case 'lbracket':
        expression = parseList(reader);
        break;
      case 'lbrace':
        expression = parseDict(reader);
        break;
      default:
        fail('unexpected ${describeToken(current)}', current.line);
    }

    return expression;
  }

  Expression parseTuple(TokenReader reader,
      {bool simplified = false,
      bool withCondition = true,
      List<String>? extraEndRules,
      bool explicitParentheses = false}) {
    Expression Function(TokenReader) parse;
    if (simplified) {
      parse = parsePrimary;
    } else if (withCondition) {
      parse = parseExpression;
    } else {
      parse = (reader) => parseExpression(reader, false);
    }

    var arguments = <Expression>[];
    var isTuple = false;

    while (true) {
      if (arguments.isNotEmpty) {
        reader.expect('comma');
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      arguments.add(parse(reader));

      if (reader.current.test('comma')) {
        isTuple = true;
      } else {
        break;
      }
    }

    if (!isTuple) {
      if (arguments.isNotEmpty) {
        return arguments.first;
      }

      if (!explicitParentheses) {
        var current = reader.current;
        fail('expected an expression, got ${describeToken(current)}',
            current.line);
      }
    }

    return Tuple(arguments);
  }

  Expression parseList(TokenReader reader) {
    reader.expect('lbracket');
    var values = <Expression>[];

    while (!reader.current.test('rbracket')) {
      if (values.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbracket')) {
        break;
      }

      values.add(parseExpression(reader));
    }

    reader.expect('rbracket');
    return Array(values);
  }

  Expression parseDict(TokenReader reader) {
    reader.expect('lbrace');
    var pairs = <Pair>[];

    while (!reader.current.test('rbrace')) {
      if (pairs.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbrace')) {
        break;
      }

      var key = parseExpression(reader);
      reader.expect('colon');
      pairs.add(Pair(key, parseExpression(reader)));
    }

    reader.expect('rbrace');
    return Dict(pairs);
  }

  Expression parsePostfix(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test('dot') || reader.current.test('lbracket')) {
        expression = parseSubscript(reader, expression);
      } else if (reader.current.test('lparen')) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.test('pipe')) {
        expression = parseFilter(reader, expression);
      } else if (reader.current.test('name', 'is')) {
        expression = parseTest(reader, expression);
      } else if (reader.current.test('lparen')) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression expression) {
    var token = reader.next();

    if (token.test('dot')) {
      var attributeToken = reader.next();

      if (attributeToken.test('name')) {
        return Attribute(attributeToken.value, expression);
      } else if (!attributeToken.test('integer')) {
        fail('expected name or number', attributeToken.line);
      }

      return Item(Constant(int.parse(attributeToken.value)), expression);
    } else if (token.test('lbracket')) {
      var key = parseExpression(reader);
      reader.expect('rbracket');
      return Item(key, expression);
    }

    fail('expected subscript expression', token.line);
  }

  void parseSignature(TokenReader reader, Callable callable) {
    var token = reader.expect('lparen');
    var arguments = callable.arguments ??= <Expression>[];
    var keywords = callable.keywords ??= <Keyword>[];
    Expression? dArguments, dKeywords;
    var requireComma = false;

    void ensure(bool ensure) {
      if (!ensure) {
        fail('invalid syntax for function call expression', token.line);
      }
    }

    while (!reader.current.test('rparen')) {
      if (requireComma) {
        reader.expect('comma');

        if (reader.current.test('rparen')) {
          break;
        }
      }

      if (reader.current.test('pow')) {
        ensure(dKeywords == null);
        reader.next();
        dKeywords = parseExpression(reader);
      } else if (reader.current.test('mul')) {
        ensure(dArguments == null && dKeywords == null);
        reader.next();
        dArguments = parseExpression(reader);
      } else {
        if (reader.current.test('name') && reader.look().test('assign')) {
          ensure(dKeywords == null);
          var key = reader.current.value;
          reader.skip(2);
          var value = parseExpression(reader);
          keywords.add(Keyword(key, value));
        } else {
          ensure(dArguments == null && dKeywords == null && keywords.isEmpty);
          arguments.add(parseExpression(reader));
        }
      }

      requireComma = true;
    }

    callable.dArguments = dArguments;
    callable.dKeywords = dKeywords;
    reader.expect('rparen');
  }

  Call parseCall(TokenReader reader, Expression expression) {
    var call = Call(expression);
    parseSignature(reader, call);
    return call;
  }

  Expression parseFilter(TokenReader reader, Expression expression) {
    var filters = parseFilters(reader);

    for (var filter in filters) {
      var arguments = filter.arguments;
      filter.expression = expression;

      if (arguments == null) {
        filter.arguments = <Expression>[expression];
      } else {
        arguments.insert(0, expression);
      }

      expression = filter;
    }

    return expression;
  }

  List<Filter> parseFilters(TokenReader reader, [bool startInline = false]) {
    var filters = <Filter>[];

    while (reader.current.test('pipe') || startInline) {
      if (!startInline) {
        reader.next();
      }

      var token = reader.expect('name');
      var filter = Filter(token.value);

      if (reader.current.test('lparen')) {
        parseSignature(reader, filter);
      }

      filters.add(filter);
      startInline = false;
    }

    return filters;
  }

  Expression parseTest(TokenReader reader, Expression expression) {
    reader.expect('name', 'is');
    var negated = false;

    if (reader.current.test('name', 'not')) {
      reader.next();
      negated = true;
    }

    var token = reader.expect('name');
    var test = Test(token.value, arguments: <Expression>[expression]);
    expression = test;
    var current = reader.current;

    const allow = ['name', 'string', 'integer', 'float', 'lbracket', 'lbrace'];
    const deny = ['name:else', 'name:or', 'name:and'];

    if (current.test('lparen')) {
      parseSignature(reader, test);
    } else if (current.testAny(allow) && !current.testAny(deny)) {
      if (current.test('name', 'is')) {
        fail('You cannot chain multiple tests with is');
      }

      var argument = parsePostfix(reader, parsePrimary(reader));
      test.arguments!.add(argument);
    }

    if (negated) {
      expression = Unary('not', expression);
    }

    return expression;
  }

  List<Node> scan(TokenReader reader) {
    return subParse(reader);
  }

  List<Node> subParse(TokenReader reader, {List<String>? endTokens}) {
    var nodes = <Node>[];
    bool? firstIsExtends;

    if (endTokens != null) {
      endTokensStack.add(endTokens);
    }

    // TODO: test conditional imports
    Node check(Node node) {
      if (firstIsExtends == null) {
        firstIsExtends = node is Extends;
      } else if (node is Extends) {
        if (firstIsExtends == false) {
          // TODO: add error message
          fail('message false');
        }

        if (firstIsExtends == true) {
          // TODO: add error message
          fail('message true');
        }
      } else if (firstIsExtends == true && node is! Block) {
        // TODO: add error message
        fail('message else');
      }

      return node;
    }

    try {
      while (!reader.current.test('eof')) {
        var token = reader.current;

        switch (token.type) {
          case 'data':
            nodes.add(Data(token.value));
            reader.next();
            break;
          case 'variable_start':
            reader.next();
            nodes.add(check(parseTuple(reader)));
            reader.expect('variable_end');
            break;
          case 'block_start':
            reader.next();

            if (endTokens != null && reader.current.testAny(endTokens)) {
              return nodes;
            }

            nodes.add(check(parseStatement(reader)));
            reader.expect('block_end');
            break;
          default:
            throw AssertionError('unsuported token type: ${token.type}');
        }
      }
    } finally {
      if (endTokens != null) {
        endTokensStack.removeLast();
      }
    }

    return nodes;
  }

  List<Node> parse(String template) {
    var tokens = environment.lexer.tokenize(template, path: path);
    var reader = TokenReader(tokens);
    return scan(reader);
  }

  @override
  String toString() {
    return 'Parser()';
  }
}
