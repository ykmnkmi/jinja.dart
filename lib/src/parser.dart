import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/lexer.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/reader.dart';
import 'package:textwrap/textwrap.dart';

class Parser {
  Parser(this.environment, {this.path})
      : endTokensStack = <List<String>>[],
        tagStack = <String>[],
        blocks = <Block>[];

  final Environment environment;

  final String? path;

  final List<List<String>> endTokensStack;

  final List<String> tagStack;

  final List<Block> blocks;

  Extends? extendsNode;

  Never fail(String message, [int? line]) {
    throw TemplateSyntaxError(message, line: line, path: path);
  }

  Never failUnknownTagEof(
    String? name,
    List<List<String>> endTokensStack, [
    int? line,
  ]) {
    var expected = <String>[];
    String? currentlyLooking;

    for (var tokens in endTokensStack) {
      expected.addAll(tokens.map<String>(describeExpression));
    }

    if (endTokensStack.isNotEmpty) {
      currentlyLooking = endTokensStack.last
          .map<String>(describeExpression)
          .map<String>((token) => "'$token'")
          .join(' or ');
    }

    var messages = <String>[];

    if (name == null) {
      messages.add('Unexpected end of template.');
    } else {
      messages.add("Encountered unknown tag '$name'.");
    }

    if (currentlyLooking != null) {
      if (name != null && expected.contains(name)) {
        messages
          ..add('You probably made a nesting mistake.')
          ..add(
              'Jinja is expecting this tag, but currently looking for $currentlyLooking.');
      } else {
        messages.add(
            'Jinja was looking for the following tags: $currentlyLooking.');
      }
    }

    if (tagStack.isNotEmpty) {
      messages.add(
          "The innermost block that needs to be closed is '${tagStack.last}'.");
    }

    fail(messages.join(' '), line);
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
    return switch (reader.current.type) {
      'variable_end' || 'block_end' || 'rparen' => true,
      _ => extraEndRules != null && extraEndRules.isNotEmpty
          ? reader.current.testAny(extraEndRules)
          : false,
    };
  }

  Node parseStatement(TokenReader reader) {
    var token = reader.current;

    if (!token.test('name')) {
      fail('Tag name expected', token.line);
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

        case 'call':
          return parseCallBlock(reader);

        case 'filter':
          return parseFilterBlock(reader);

        case 'macro':
          return parseMacro(reader);

        case 'do':
          return parseDo(reader);

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

  Node parseStatements(
    TokenReader reader,
    List<String> endTokens, [
    bool dropNeedle = false,
  ]) {
    reader.skipIf('colon');
    reader.expect('block_end');

    var nodes = subParse(reader, endTokens: endTokens);

    if (reader.current.test('eof')) {
      failEof(endTokens);
    }

    if (dropNeedle) {
      reader.next();
    }

    if (nodes.length == 1) {
      return nodes.first;
    }

    return Output(nodes: nodes);
  }

  Statement parseSet(TokenReader reader) {
    const endSet = <String>['name:endset'];

    reader.expect('name', 'set');

    var target = parseAssignNameSpace(reader);

    if (reader.skipIf('assign')) {
      var expression = parseTuple(reader);
      return Assign(target: target, value: expression);
    }

    var filters = parseFilters(reader);
    var body = parseStatements(reader, endSet, true);
    return AssignBlock(target: target, filters: filters, body: body);
  }

  For parseFor(TokenReader reader) {
    const endForElse = <String>['name:endfor', 'name:else'];

    reader.expect('name', 'for');

    var target = parseAssignTarget(reader, extraEndRules: <String>['name:in']);

    if (target case Name(name: 'loop')) {
      fail("Can't assign to special loop variable in for-loop target");
    }

    reader.expect('name', 'in');

    var iterable = parseTuple(reader, withCondition: false);
    Expression? test;

    if (reader.skipIf('name', 'if')) {
      test = parseExpression(reader);
    }

    var recursive = reader.skipIf('name', 'recursive');
    var body = parseStatements(reader, endForElse);
    Node? orElse;

    if (reader.next().test('name', 'else')) {
      orElse = parseStatements(reader, <String>['name:endfor'], true);
    }

    return For(
      target: target,
      iterable: iterable,
      body: body,
      orElse: orElse,
      test: test,
      recursive: recursive,
    );
  }

  If parseIf(TokenReader reader) {
    const endIf = <String>['name:endif'];
    const endIfElseEndIf = <String>['name:elif', 'name:else', 'name:endif'];

    reader.expect('name', 'if');

    var test = parseExpression(reader, false);
    var body = parseStatements(reader, endIfElseEndIf);
    var root = If(test: test, body: body);
    var ifNodes = <If>[root];
    Token tag;

    while (true) {
      tag = reader.next();

      if (tag.test('name', 'elif')) {
        var test = parseTuple(reader, withCondition: false);
        var body = parseStatements(reader, endIfElseEndIf);
        var elif = If(test: test, body: body);
        ifNodes.add(elif);
        continue;
      }

      break;
    }

    Node? orElse;

    if (tag.test('name', 'else')) {
      orElse = parseStatements(reader, endIf, true);
    }

    var node = ifNodes.last.copyWith(orElse: orElse);

    for (var ifNode in ifNodes.reversed.skip(1)) {
      node = ifNode.copyWith(orElse: node);
    }

    return node;
  }

  With parseWith(TokenReader reader) {
    const endWith = <String>['name:endwith'];

    reader.expect('name', 'with');

    var targets = <Expression>[];
    var values = <Expression>[];

    while (!reader.current.test('block_end')) {
      if (targets.isNotEmpty) {
        reader.expect('comma');
      }

      var target = parseAssignTarget(reader, context: AssignContext.parameter);
      targets.add(target);
      reader.expect('assign');
      values.add(parseExpression(reader));
    }

    var body = parseStatements(reader, endWith, true);
    return With(targets: targets, values: values, body: body);
  }

  AutoEscape parseAutoEscape(TokenReader reader) {
    const endAutoEscape = <String>['name:endautoescape'];

    reader.expect('name', 'autoescape');

    var value = parseExpression(reader);
    var body = parseStatements(reader, endAutoEscape, true);
    return AutoEscape(value: value, body: body);
  }

  Block parseBlock(TokenReader reader) {
    const endBlock = <String>['name:endblock'];

    var token = reader.next();
    var name = reader.expect('name');

    if (blocks.any((block) => block.name == name.value)) {
      fail("Block '${name.value}' defined twice", reader.current.line);
    }

    var scoped = reader.skipIf('name', 'scoped');

    if (reader.current.test('sub')) {
      fail('Use an underscore instead', reader.current.line);
    }

    var required = reader.skipIf('name', 'required');
    var body = parseStatements(reader, endBlock, true);

    if (required) {
      switch (body) {
        case Data data when data.isLeaf:
        case Output(nodes: <Node>[]):
          break;

        default:
          fail('Required blocks can only contain comments or whitespace',
              token.line);
      }
    }

    var maybeName = reader.current;

    if (maybeName.test('name')) {
      if (maybeName.value != name.value) {
        fail("'${name.value}' expected, got ${maybeName.value}");
      }

      reader.next();
    }

    var block = Block(
      name: name.value,
      scoped: scoped,
      required: required,
      body: body,
    );

    blocks.add(block);
    return block;
  }

  Extends parseExtends(TokenReader reader) {
    var token = reader.next();
    var primary = parsePrimary(reader);

    if (primary is! Constant) {
      fail('Template path literal expected', reader.current.line);
    }

    if (extendsNode != null) {
      fail('Extended multiple times', token.line);
    }

    var node = Extends(path: primary.value as String);
    extendsNode = node;
    return node;
  }

  bool parseImportContext(
    TokenReader reader, [
    bool defaultValue = true,
  ]) {
    var keywords = <String>['name:with', 'name:without'];
    bool withContext;

    if (reader.current.testAny(keywords) &&
        reader.look().test('name', 'context')) {
      withContext = reader.current.value == 'with';
      reader.skip(2);
    } else {
      withContext = defaultValue;
    }

    return withContext;
  }

  Include parseInclude(TokenReader reader) {
    reader.next();

    var name = reader.expect('string');
    var withContext = parseImportContext(reader, true);
    return Include(template: name.value, withContext: withContext);
  }

  // TODO: add parseImport

  // TODO: add parseFrom

  List<(Expression, Expression?)> parseSignature(TokenReader reader) {
    var names = <Expression>[];
    var defaults = <Expression?>[];

    reader.expect('lparen');

    while (!reader.current.test('rparen')) {
      if (names.isNotEmpty) {
        reader.expect('comma');
      }

      var name = parseAssignName(reader, AssignContext.parameter);

      if (reader.skipIf('assign')) {
        defaults.add(parseExpression(reader));
      } else if (defaults.isNotEmpty && defaults.last != null) {
        fail('non-default argument follows default argument');
      } else {
        defaults.add(null);
      }

      names.add(name);
    }

    reader.expect('rparen');

    return <(Expression, Expression?)>[
      for (var i = 0; i < names.length; i += 1) (names[i], defaults[i])
    ];
  }

  CallBlock parseCallBlock(TokenReader reader) {
    const endCall = <String>['name:endcall'];

    var token = reader.next();

    List<(Expression, Expression?)> arguments;

    if (reader.current.test('lparen')) {
      arguments = parseSignature(reader);
    } else {
      arguments = const <(Expression, Expression?)>[];
    }

    var call = parseExpression(reader);

    if (call is! Call) {
      fail('expected call', token.line);
    }

    var body = parseStatements(reader, endCall, true);
    return CallBlock(call: call, arguments: arguments, body: body);
  }

  FilterBlock parseFilterBlock(TokenReader reader) {
    const endFilter = <String>['name:endfilter'];

    reader.next();

    var filters = parseFilters(reader, true);
    var body = parseStatements(reader, endFilter, true);
    return FilterBlock(filters: filters, body: body);
  }

  Macro parseMacro(TokenReader reader) {
    const endMacro = <String>['name:endmacro'];

    reader.next();

    var name = parseAssignName(reader);
    var arguments = parseSignature(reader);
    var body = parseStatements(reader, endMacro, true);

    var varargs = false, kwargs = false, caller = false;

    for (var name in body.findAll<Name>()) {
      switch (name.name) {
        case 'varargs':
          varargs = true;
          break;
        case 'kwargs':
          kwargs = true;
          break;
        case 'caller':
          caller = true;
          break;
        default:
      }
    }

    return Macro(
      name: name.name,
      arguments: arguments,
      varargs: varargs,
      kwargs: kwargs,
      caller: caller,
      body: body,
    );
  }

  // TODO: add parsePrint

  Name parseAssignName(
    TokenReader reader, [
    AssignContext context = AssignContext.store,
  ]) {
    var name = reader.expect('name');
    return Name(name: name.value, context: context);
  }

  Expression parseAssignNameSpace(TokenReader reader) {
    var line = reader.current.line;

    if (reader.look().test('dot')) {
      var namespace = reader.expect('name');
      reader.expect('dot'); // skip dot

      var attribute = reader.expect('name');
      return NamespaceRef(name: namespace.value, attribute: attribute.value);
    }

    var name = parsePrimary(reader);

    if (name case Name name) {
      return name.copyWith(context: AssignContext.store);
    }

    fail("Can't assign to ${name.runtimeType}", line);
  }

  Expression parseAssignTarget(
    TokenReader reader, {
    List<String>? extraEndRules,
    bool withTuple = true,
    AssignContext context = AssignContext.store,
  }) {
    var line = reader.current.line;
    Expression target;

    if (withTuple) {
      target = parseTuple(
        reader,
        simplified: true,
        extraEndRules: extraEndRules,
      );
    } else {
      target = parsePrimary(reader);
    }

    if (target case Name name) {
      return name.copyWith(context: context);
    }

    if (target case Tuple(values: var values)
        when values.any((value) => value is Name)) {
      return target.copyWith(
        values: <Expression>[
          for (var value in target.values.cast<Name>())
            value.copyWith(context: context)
        ],
      );
    }

    fail("Can't assign to ${target.runtimeType}", line);
  }

  Do parseDo(TokenReader reader) {
    reader.expect('name', 'do');

    return Do(value: parseTuple(reader));
  }

  Expression parseExpression(TokenReader reader, [bool withCondition = true]) {
    if (withCondition) {
      return parseCondition(reader);
    }

    return parseOr(reader);
  }

  Expression parseCondition(TokenReader reader, [bool withCondExpr = true]) {
    var value = parseOr(reader);

    while (reader.skipIf('name', 'if')) {
      var condition = parseOr(reader);

      if (reader.skipIf('name', 'else')) {
        var orElse = parseCondition(reader);
        value =
            Condition(test: condition, trueValue: value, falseValue: orElse);
      } else {
        value = Condition(test: condition, trueValue: value);
      }
    }

    return value;
  }

  Expression parseOr(TokenReader reader) {
    var left = parseAnd(reader);

    while (reader.skipIf('name', 'or')) {
      var right = parseAnd(reader);
      left = Logical(operator: LogicalOperator.or, left: left, right: right);
    }

    return left;
  }

  Expression parseAnd(TokenReader reader) {
    var left = parseNot(reader);

    while (reader.skipIf('name', 'and')) {
      var right = parseNot(reader);
      left = Logical(operator: LogicalOperator.and, left: left, right: right);
    }

    return left;
  }

  Expression parseNot(TokenReader reader) {
    if (reader.current.test('name', 'not')) {
      reader.next();

      var value = parseNot(reader);
      return Unary(operator: UnaryOperator.not, value: value);
    }

    return parseCompare(reader);
  }

  Expression parseCompare(TokenReader reader) {
    const operators = <String>['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'];

    var value = parseMath1(reader);
    var operands = <Operand>[];

    outer:
    while (true) {
      CompareOperator operator;

      if (reader.current.testAny(operators)) {
        var token = reader.current;

        reader.next();

        operator = CompareOperator.parse(token.type);
      } else if (reader.skipIf('name', 'in')) {
        operator = CompareOperator.contains;
      } else if (reader.current.test('name', 'not') &&
          reader.look().test('name', 'in')) {
        reader.skip(2);

        operator = CompareOperator.notContains;
      } else {
        break outer;
      }

      operands.add((operator, parseMath1(reader)));
    }

    if (operands.isEmpty) {
      return value;
    }

    return Compare(value: value, operands: operands);
  }

  Expression parseMath1(TokenReader reader) {
    var left = parseConcat(reader);

    outer:
    while (true) {
      ScalarOperator operator;

      switch (reader.current.type) {
        case 'add':
          reader.next();
          operator = ScalarOperator.plus;
          break;

        case 'sub':
          reader.next();
          operator = ScalarOperator.minus;
          break;

        default:
          break outer;
      }

      var right = parseConcat(reader);
      left = Scalar(operator: operator, left: left, right: right);
    }

    return left;
  }

  Expression parseConcat(TokenReader reader) {
    var values = <Expression>[parseMath2(reader)];

    while (reader.current.test('tilde')) {
      reader.next();

      values.add(parseMath2(reader));
    }

    if (values.length == 1) {
      return values[0];
    }

    return Concat(values: values);
  }

  Expression parseMath2(TokenReader reader) {
    var left = parsePow(reader);

    outer:
    while (true) {
      ScalarOperator operator;

      switch (reader.current.type) {
        case 'mul':
          reader.next();

          operator = ScalarOperator.multiple;
          break;

        case 'div':
          reader.next();

          operator = ScalarOperator.division;
          break;

        case 'floordiv':
          reader.next();

          operator = ScalarOperator.floorDivision;
          break;

        case 'mod':
          reader.next();

          operator = ScalarOperator.module;
          break;

        default:
          break outer;
      }

      var right = parsePow(reader);
      left = Scalar(operator: operator, left: left, right: right);
    }

    return left;
  }

  Expression parsePow(TokenReader reader) {
    var left = parseUnary(reader);

    while (reader.current.test('pow')) {
      reader.next();

      var right = parseUnary(reader);
      left = Scalar(operator: ScalarOperator.power, left: left, right: right);
    }

    return left;
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression value;

    switch (reader.current.type) {
      case 'add':
        reader.next();

        value = parseUnary(reader, withFilter: false);
        value = Unary(operator: UnaryOperator.plus, value: value);
        break;

      case 'sub':
        reader.next();

        value = parseUnary(reader, withFilter: false);
        value = Unary(operator: UnaryOperator.minus, value: value);
        break;

      default:
        value = parsePrimary(reader);
    }

    value = parsePostfix(reader, value);

    if (withFilter) {
      value = parseFilterExpression(reader, value);
    }

    return value;
  }

  Expression parsePrimary(TokenReader reader) {
    var current = reader.current;
    Expression expression;

    switch (current.type) {
      case 'name':
        switch (current.value) {
          case 'False' || 'false':
            expression = const Constant(value: false);
            break;

          case 'True' || 'true':
            expression = const Constant(value: true);
            break;

          case 'None' || 'none' || 'null':
            expression = const Constant(value: null);
            break;

          default:
            expression = Name(name: current.value);
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

        var value = buffer.toString();
        // TODO(parser): replace all escaped characters
        value = value.replaceAll(r'\\r', '\r').replaceAll(r'\\n', '\n');
        expression = Constant(value: value);
        break;

      case 'integer':
      case 'float':
        expression = Constant(value: num.parse(current.value));

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
        fail('Unexpected ${describeToken(current)}', current.line);
    }

    return expression;
  }

  Expression parseTuple(
    TokenReader reader, {
    bool simplified = false,
    bool withCondition = true,
    List<String>? extraEndRules,
    bool explicitParentheses = false,
  }) {
    Expression Function(TokenReader) parse;

    if (simplified) {
      parse = parsePrimary;
    } else if (withCondition) {
      parse = parseExpression;
    } else {
      parse = (reader) => parseExpression(reader, false);
    }

    var values = <Expression>[];
    var isTuple = false;

    while (true) {
      if (values.isNotEmpty) {
        reader.expect('comma');
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      values.add(parse(reader));

      if (reader.current.test('comma')) {
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
        var current = reader.current;
        fail('Expected an expression, got ${describeToken(current)}',
            current.line);
      }
    }

    return Tuple(values: values);
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

    return Array(values: values);
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

      var value = parseExpression(reader);
      pairs.add((key: key, value: value));
    }

    reader.expect('rbrace');

    return Dict(pairs: pairs);
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

  Expression parseSubscript(TokenReader reader, Expression value) {
    var token = reader.next();

    if (token.test('dot')) {
      var attributeToken = reader.next();

      if (attributeToken.test('name')) {
        return Attribute(attribute: attributeToken.value, value: value);
      }

      if (!attributeToken.test('integer')) {
        fail('Expected name or number', attributeToken.line);
      }

      var key = Constant(value: int.parse(attributeToken.value));
      return Item(key: key, value: value);
    }

    if (token.test('lbracket')) {
      var key = parseExpression(reader);
      reader.expect('rbracket');
      return Item(key: key, value: value);
    }

    fail('Expected subscript expression', token.line);
  }

  Calling parseCalling(TokenReader reader) {
    var token = reader.expect('lparen');
    var arguments = <Expression>[];
    var keywords = <Keyword>[];
    var requireComma = false;
    Expression? dArguments, dKeywords;

    void ensure(bool ensure) {
      if (!ensure) {
        fail('Invalid syntax for function call expression', token.line);
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

          if (key == 'default') {
            key = 'defaultValue';
          }

          keywords.add((key: key, value: value));
        } else {
          ensure(dArguments == null && dKeywords == null && keywords.isEmpty);
          arguments.add(parseExpression(reader));
        }
      }

      requireComma = true;
    }

    reader.expect('rparen');

    return Calling(
      arguments: arguments,
      keywords: keywords,
      dArguments: dArguments,
      dKeywords: dKeywords,
    );
  }

  Call parseCall(TokenReader reader, Expression expression) {
    var calling = parseCalling(reader);
    return Call(value: expression, calling: calling);
  }

  Expression parseFilter(TokenReader reader, Expression expression) {
    var filters = parseFilters(reader);

    for (var filter in filters) {
      expression = filter.copyWith(
        calling: filter.calling.copyWith(
          arguments: <Expression>[expression, ...filter.calling.arguments],
        ),
      );
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
      var filter = Filter(name: token.value);

      if (reader.current.test('lparen')) {
        var calling = parseCalling(reader);
        filter = filter.copyWith(calling: calling);
      }

      filters.add(filter);
      startInline = false;
    }

    return filters;
  }

  Expression parseTest(TokenReader reader, Expression expression) {
    const allow = <String>[
      'name', 'string', 'integer', //
      'float', 'lbracket', 'lbrace',
    ];

    const deny = <String>['name:else', 'name:or', 'name:and'];

    reader.expect('name', 'is');

    var negated = false;

    if (reader.current.test('name', 'not')) {
      reader.next();

      negated = true;
    }

    var token = reader.expect('name');
    var current = reader.current;
    Calling calling;

    if (current.test('lparen')) {
      calling = parseCalling(reader);

      var arguments = <Expression>[expression, ...calling.arguments];
      calling = calling.copyWith(arguments: arguments);
    } else if (current.testAny(allow) && !current.testAny(deny)) {
      if (current.test('name', 'is')) {
        fail('You cannot chain multiple tests with is');
      }

      var argument = parsePostfix(reader, parsePrimary(reader));
      calling = Calling(arguments: <Expression>[expression, argument]);
    } else {
      calling = Calling(arguments: <Expression>[expression]);
    }

    expression = Test(name: token.value, calling: calling);

    if (negated) {
      expression = Unary(operator: UnaryOperator.not, value: expression);
    }

    return expression;
  }

  Node scan(List<Token> tokens) {
    var reader = TokenReader(tokens);
    var nodes = subParse(reader);

    if (extendsNode case var extendsNode?) {
      nodes = <Node>[extendsNode];
    }

    if (blocks.isEmpty) {
      if (nodes.length == 1) {
        return nodes.first;
      }

      return Output(nodes: nodes);
    }

    return TemplateNode(blocks: blocks.toList(), body: Output(nodes: nodes));
  }

  List<Node> subParse(TokenReader reader, {List<String>? endTokens}) {
    var nodes = <Node>[];

    if (endTokens != null) {
      endTokensStack.add(endTokens);
    }

    try {
      while (!reader.current.test('eof')) {
        var token = reader.current;

        switch (token.type) {
          case 'data':
            nodes.add(Data(data: token.value));

            reader.next();
            break;

          case 'variable_start':
            reader.next();

            nodes.add(Interpolation(value: parseTuple(reader)));

            reader.expect('variable_end');
            break;

          case 'block_start':
            reader.next();

            if (endTokens != null && reader.current.testAny(endTokens)) {
              return nodes;
            }

            var node = parseStatement(reader);

            if (extendsNode != null && node is! Block) {
              fill('');
            }

            nodes.add(node);

            reader.expect('block_end');
            break;

          default:
            assert(false, 'Unreachable');
        }
      }
    } finally {
      if (endTokens != null) {
        endTokensStack.removeLast();
      }
    }

    return nodes;
  }

  Node parse(String template) {
    var tokens = environment.lex(template, path: path);
    return scan(tokens);
  }
}
