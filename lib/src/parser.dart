import 'package:jinja/runtime.dart';

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
    final expected = <String>[];
    String? currentlyLooking;

    for (final tokens in endTokensStack) {
      expected.addAll(tokens.map<String>(describeExpression));
    }

    if (endTokensStack.isNotEmpty) {
      currentlyLooking = endTokensStack.last
          .map<String>(describeExpression)
          .map<String>((token) => '\'$token\'')
          .join(' or ');
    }

    final message = name == null
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
    final stack = endTokensStack.toList();
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

  Node parseStatement(TokenReader reader) {
    final token = reader.current;

    if (!token.test('name')) {
      fail('tag name expected', token.line);
    }

    tagStack.add(token.value);
    var popTag = true;

    try {
      switch (token.value) {
        case 'set':
          return parseSet(reader);
        case 'for':
          return parseFor(reader);
        case 'if':
          return parseIf(reader);
        case 'with':
          return parseWith(reader);
        case 'autoescape':
          return parseAutoEscape(reader);
        case 'block':
          return parseBlock(reader);
        case 'extends':
          return parseExtends(reader);
        case 'include':
          return parseInclude(reader);
        case 'filter':
          return parseFilterBlock(reader);
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
    final nodes = subParse(reader, endTokens: endTokens);

    if (reader.current.test('eof')) {
      failEof(endTokens);
    }

    if (dropNeedle) {
      reader.next();
    }

    return nodes;
  }

  Statement parseSet(TokenReader reader) {
    reader.expect('name', 'set');
    final target = parseAssignTarget(reader, withNamespace: true);

    if (reader.skipIf('assign')) {
      final expression = parseTuple(reader);
      return Assign(target, expression);
    }

    final filters = parseFilters(reader, true);
    final body = parseStatements(reader, <String>['name:endset'], true);
    return AssignBlock(target, body, filters);
  }

  For parseFor(TokenReader reader) {
    reader.expect('name', 'for');
    final target =
        parseAssignTarget(reader, extraEndRules: <String>['name:in']);

    if (target is Name && target.name == 'loop') {
      fail('can\'t assign to special loop variable in for-loop target');
    }

    reader.expect('name', 'in');
    final iterable = parseTuple(reader, withCondition: false);
    Test? test;

    if (reader.skipIf('name', 'if')) {
      final expression = parseExpression(reader);
      test = expression is Test
          ? expression
          : Test('defined', arguments: <Expression>[expression]);
    }

    final recursive = reader.skipIf('name', 'recursive');
    final body = parseStatements(reader, <String>['name:endfor', 'name:else']);
    var hasLoop = false;

    body:
    for (final node in body) {
      for (final name in node.listExpressions<Name>()) {
        if (name.name == 'loop') {
          hasLoop = true;
          break body;
        }
      }
    }

    List<Node>? orElse;

    if (reader.next().test('name', 'else')) {
      orElse = parseStatements(reader, <String>['name:endfor'], true);
    }

    return For(target, iterable, body,
        hasLoop: hasLoop, orElse: orElse, test: test, recursive: recursive);
  }

  If parseIf(TokenReader reader) {
    reader.expect('name', 'if');
    var test = parseTuple(reader, withCondition: false);
    var body = parseStatements(
        reader, <String>['name:elif', 'name:else', 'name:endif']);
    var root = If(test, body);
    var node = root;

    while (true) {
      var tag = reader.next();

      if (tag.test('name', 'elif')) {
        var test = parseTuple(reader, withCondition: false);
        var body = parseStatements(
            reader, <String>['name:elif', 'name:else', 'name:endif']);
        node.nextIf = If(test, body);
        node = node.nextIf!;
        continue;
      }

      if (tag.test('name', 'else')) {
        root.orElse = parseStatements(reader, <String>['name:endif'], true);
      }

      break;
    }

    return root;
  }

  With parseWith(TokenReader reader) {
    reader.expect('name', 'with');
    final targets = <Expression>[];
    final values = <Expression>[];

    while (!reader.current.test('block_end')) {
      if (targets.isNotEmpty) {
        reader.expect('comma');
      }

      final target = parseAssignTarget(reader);
      (target as Assignable).context = AssignContext.parameter;
      targets.add(target);
      reader.expect('assign');
      values.add(parseExpression(reader));
    }

    final body = parseStatements(reader, <String>['name:endwith'], true);
    return With(targets, values, body);
  }

  Scope parseAutoEscape(TokenReader reader) {
    reader.expect('name', 'autoescape');
    final escape = parseExpression(reader);
    final body = parseStatements(reader, <String>['name:endautoescape'], true);
    return Scope(ScopedContextModifier(
        <String, Expression>{'autoEscape': escape}, body));
  }

  Block parseBlock(TokenReader reader) {
    reader.expect('name', 'block');
    final name = reader.expect('name');

    if (blocks.contains(name.value)) {
      fail('block \'${name.value}\' defined twice', reader.current.line);
    }

    final scoped = reader.skipIf('name', 'scoped');

    if (reader.current.test('sub')) {
      fail('use an underscore instead', reader.current.line);
    }

    final required = reader.skipIf('name', 'required');
    final body = parseStatements(reader, <String>['name:endblock'], true);
    var hasSuper = false;

    for (final node in body) {
      for (final child in node.listChildrens(deep: true)) {
        if (child is Data && child.trimmed.isEmpty) {
          continue;
        }

        throw TemplateSyntaxError(
            'required blocks can only contain comments or whitespace');
      }

      for (final name in node.listExpressions<Name>()) {
        if (name.name == 'super') {
          hasSuper = true;
          break;
        }
      }
    }

    final maybeName = reader.current;

    if (maybeName.test('name')) {
      if (maybeName.value != name.value) {
        // TODO: update error message
        fail('\'${name.value}\' expected, got ${maybeName.value}');
      }

      reader.next();
    }

    return Block(name.value, scoped, required, hasSuper, body);
  }

  Extends parseExtends(TokenReader reader) {
    reader.expect('name', 'extends');
    final node = parsePrimary(reader);

    if (node is! Constant) {
      // TODO: update error message
      fail('template name or path expected');
    }

    return Extends(node.value as String);
  }

  T parseImportContext<T extends ImportContext>(
    TokenReader reader,
    T node, [
    bool defaultValue = true,
  ]) {
    if (reader.current.testAny(<String>['name:with', 'name:without']) &&
        reader.look().test('name', 'context')) {
      node.withContext = reader.current.value == 'with';
      reader.skip(2);
    } else {
      node.withContext = defaultValue;
    }

    return node;
  }

  Include parseInclude(TokenReader reader) {
    reader.expect('name', 'include');
    final name = reader.expect('string');
    final node = Include(name.value);
    return parseImportContext<Include>(reader, node, true);
  }

  FilterBlock parseFilterBlock(TokenReader reader) {
    reader.expect('name', 'filter');
    final filters = parseFilters(reader, true);
    final body = parseStatements(reader, <String>['name:endfilter'], true);
    return FilterBlock(filters, body);
  }

  Expression parseAssignTarget(
    TokenReader reader, {
    List<String>? extraEndRules,
    bool nameOnly = false,
    bool withNamespace = false,
    bool withTuple = true,
  }) {
    final line = reader.current.line;
    Expression target;

    if (withNamespace && reader.look().test('dot')) {
      final namespace = reader.expect('name');
      reader.next(); // skip dot
      final attribute = reader.expect('name');

      target = NamespaceRef(namespace.value, attribute.value);
    } else if (nameOnly) {
      final name = reader.expect('name');

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

  Expression parseExpression(TokenReader reader, [bool withCondition = true]) {
    return withCondition ? parseCondition(reader) : parseOr(reader);
  }

  Expression parseCondition(TokenReader reader, [bool withCondExpr = true]) {
    var whenTrue = parseOr(reader);

    while (reader.skipIf('name', 'if')) {
      final condition = parseOr(reader);

      if (reader.skipIf('name', 'else')) {
        final whenFalse = parseCondition(reader);
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
    final expression = parseMath1(reader);
    final operands = <Operand>[];
    String type;

    while (true) {
      if (reader.current.testAny(['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'])) {
        type = reader.current.type;
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
    final expressions = <Expression>[parseMath2(reader)];

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
    final current = reader.current;
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
        final buffer = StringBuffer(current.value);
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

    final arguments = <Expression>[];
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
        final current = reader.current;
        fail('expected an expression, got ${describeToken(current)}',
            current.line);
      }
    }

    return TupleLiteral(arguments);
  }

  Expression parseList(TokenReader reader) {
    reader.expect('lbracket');
    final values = <Expression>[];

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
    return ListLiteral(values);
  }

  Expression parseDict(TokenReader reader) {
    reader.expect('lbrace');
    final entries = <MapEntry<Expression, Expression>>[];

    while (!reader.current.test('rbrace')) {
      if (entries.isNotEmpty) {
        reader.expect('comma');
      }

      if (reader.current.test('rbrace')) {
        break;
      }

      final key = parseExpression(reader);
      reader.expect('colon');
      final value = parseExpression(reader);
      entries.add(MapEntry<Expression, Expression>(key, value));
    }

    reader.expect('rbrace');

    return DictLiteral(entries);
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
    final token = reader.next();

    if (token.test('dot')) {
      final attributeToken = reader.next();

      if (attributeToken.test('name')) {
        return Attribute(attributeToken.value, expression);
      } else if (!attributeToken.test('integer')) {
        fail('expected name or number', attributeToken.line);
      }

      return Item(Constant(int.parse(attributeToken.value)), expression);
    } else if (token.test('lbracket')) {
      final arguments = <Expression>[];

      while (!reader.current.test('rbracket')) {
        if (arguments.isNotEmpty) {
          reader.expect('comma');
        }

        arguments.add(parseSubscribed(reader));
      }

      reader.expect('rbracket');

      if (arguments.length == 1) {
        return Item(arguments[0], expression);
      } else {
        return Item(TupleLiteral(arguments), expression);
      }
    }

    fail('expected subscript expression', token.line);
  }

  Expression parseSubscribed(TokenReader reader) {
    final arguments = <Expression?>[];

    if (reader.current.test('colon')) {
      reader.next();
      arguments.add(null);
    } else {
      final expression = parseExpression(reader);

      if (!reader.current.test('colon')) {
        return expression;
      }

      reader.next();
      arguments.add(expression);
    }

    if (reader.current.test('colon')) {
      arguments.add(null);
    } else if (!reader.current.test('rbracket') &&
        !reader.current.test('comma')) {
      arguments.add(parseExpression(reader));
    } else {
      arguments.add(null);
    }

    if (reader.current.test('colon')) {
      reader.next();

      if (!reader.current.test('rbracket') && !reader.current.test('comma')) {
        arguments.add(parseExpression(reader));
      } else {
        arguments.add(null);
      }
    } else {
      arguments.add(null);
    }

    return Slice.fromList(arguments);
  }

  void parseCallableArguments(TokenReader reader, Callable callable) {
    final token = reader.expect('lparen');
    final arguments = callable.arguments ?? <Expression>[];
    final keywords = callable.keywords ?? <Keyword>[];
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
          final key = reader.current.value;
          reader.skip(2);
          final value = parseExpression(reader);
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
    final call = Call(expression);
    parseCallableArguments(reader, call);
    return call;
  }

  Expression parseFilter(TokenReader reader, Expression expression) {
    final filters = parseFilters(reader);

    for (final filter in filters) {
      final arguments = filter.arguments;

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
    final filters = <Filter>[];

    while (reader.current.test('pipe') || startInline) {
      if (!startInline) {
        reader.next();
      }

      final token = reader.expect('name');
      final filter = Filter(token.value);

      if (reader.current.test('lparen')) {
        parseCallableArguments(reader, filter);
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

    final token = reader.expect('name');
    final test = Test(token.value, arguments: <Expression>[expression]);
    expression = test;
    final current = reader.current;

    const allow = ['name', 'string', 'integer', 'float', 'lbracket', 'lbrace'];
    const deny = ['name:else', 'name:or', 'name:and'];

    if (current.test('lparen')) {
      parseCallableArguments(reader, test);
    } else if (current.testAny(allow) && !current.testAny(deny)) {
      if (current.test('name', 'is')) {
        fail('You cannot chain multiple tests with is');
      }

      final argument = parsePostfix(reader, parsePrimary(reader));
      final arguments = test.arguments;

      if (arguments == null) {
        test.arguments = <Expression>[argument];
      } else {
        arguments.add(argument);
      }
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
    final buffer = <Node>[];
    final nodes = <Node>[];
    bool? firstNodeType;

    if (endTokens != null) {
      endTokensStack.add(endTokens);
    }

    // TODO: test conditional imports
    void check(Node node) {
      if (firstNodeType == null) {
        firstNodeType = node is Extends;
      } else if (node is Extends) {
        if (firstNodeType == false) {
          // TODO: add error message
          fail('message false');
        }

        if (firstNodeType == true) {
          // TODO: add error message
          fail('message true');
        }
      } else if (firstNodeType == true && node is! Block) {
        // TODO: add error message
        fail('message else');
      }
    }

    void flushData() {
      if (buffer.isNotEmpty) {
        buffer.forEach(check);
        nodes.addAll(buffer);
        buffer.clear();
      }
    }

    try {
      while (!reader.current.test('eof')) {
        final token = reader.current;

        switch (token.type) {
          case 'data':
            buffer.add(Data(token.value));
            reader.next();
            break;
          case 'variable_start':
            reader.next();
            buffer.add(parseTuple(reader));
            reader.expect('variable_end');
            break;
          case 'block_start':
            flushData();
            reader.next();

            if (endTokens != null && reader.current.testAny(endTokens)) {
              return nodes;
            }

            final node = parseStatement(reader);
            check(node);
            nodes.add(node);
            reader.expect('block_end');
            break;
          default:
            throw AssertionError('unsuported token type: ${token.type}');
        }
      }

      flushData();
    } finally {
      if (endTokens != null) {
        endTokensStack.removeLast();
      }
    }

    return nodes;
  }

  Template parse(String template) {
    final tokens = environment.lexer.tokenize(template, path: path);
    final reader = TokenReader(tokens);
    final nodes = scan(reader);
    final blocks = <Block>[];
    var hasSelf = false;

    if (nodes.isNotEmpty) {
      if (nodes[0] is Extends) {
        nodes.length = 1;
      } else {
        for (final node in nodes) {
          for (final child in node.listChildrens(deep: true)) {
            if (!hasSelf) {
              for (final name in child.listExpressions<Name>()) {
                if (name.name == 'self') {
                  hasSelf = true;
                  break;
                }
              }
            }

            if (child is Block) {
              blocks.add(child);
            }
          }
        }
      }
    }

    return Template.parsed(environment, nodes,
        blocks: blocks, hasSelf: hasSelf, path: path);
  }

  @override
  String toString() {
    return 'Parser()';
  }
}
