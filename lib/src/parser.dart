import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/lexer.dart';
import 'package:jinja/src/nodes.dart';
import 'package:textwrap/textwrap.dart';

final class Parser {
  Parser(this.environment, {this.path})
    : endTokensStack = <List<(String, String?)>>[],
      tagStack = <String>[],
      blocks = <String>{};

  final Environment environment;

  final String? path;

  final List<List<(String, String?)>> endTokensStack;

  final List<String> tagStack;

  final Set<String> blocks;

  Extends? extendsNode;

  Never fail(String message, [int? line]) {
    throw TemplateSyntaxError(message, line: line, path: path);
  }

  Never failUnknownTagEof(
    String? name,
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
            'Jinja is expecting this tag, but currently looking for $currentlyLooking.',
          );
      } else {
        messages.add(
          'Jinja was looking for the following tags: $currentlyLooking.',
        );
      }
    }

    if (tagStack.isNotEmpty) {
      messages.add(
        "The innermost block that needs to be closed is '${tagStack.last}'.",
      );
    }

    fail(messages.join(' '), line);
  }

  Never failUnknownTag(String name, [int? line]) {
    failUnknownTagEof(name, endTokensStack, line);
  }

  Never failEof(List<(String, String?)> endTokens, [int? line]) {
    var stack = endTokensStack.toList();
    stack.add(endTokens);
    failUnknownTagEof(null, stack, line);
  }

  bool isTupleEnd(
    TokenReader reader, [
    List<(String, String?)>? extraEndRules,
  ]) {
    return switch (reader.current.type) {
      TokenType.variableEnd || TokenType.blockEnd || TokenType.rParen => true,
      _ =>
        extraEndRules != null && extraEndRules.isNotEmpty
            ? reader.current.matchAny(extraEndRules)
            : false,
    };
  }

  Node parseStatement(TokenReader reader) {
    var token = reader.current;

    if (token.type != TokenType.name) {
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

        case 'block':
          return parseBlock(reader);

        case 'extends':
          return parseExtends(reader);

        case 'include':
          return parseInclude(reader);

        case 'import':
          return parseImport(reader);

        case 'from':
          return parseFrom(reader);

        case 'call':
          return parseCallBlock(reader);

        case 'filter':
          return parseFilterBlock(reader);

        case 'macro':
          return parseMacro(reader);

        case 'do':
          return parseDo(reader);

        case 'try':
          return parseTryCatch(reader);

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
    List<(String, String?)> endTokens, [
    bool dropNeedle = false,
  ]) {
    reader.skipIf(TokenType.colon);
    reader.expect(TokenType.blockEnd);

    var nodes = subParse(reader, endTokens: endTokens);

    if (reader.current.type == TokenType.eof) {
      failEof(endTokens);
    }

    if (dropNeedle) {
      reader.next();
    }

    if (nodes.isEmpty) {
      return Data(data: '');
    }

    if (nodes.length == 1) {
      return nodes[0];
    }

    return Output(nodes: nodes);
  }

  Statement parseSet(TokenReader reader) {
    const endSet = <(String, String?)>[(TokenType.name, 'endset')];

    reader.expect(TokenType.name, 'set');

    var target = parseAssignNameSpace(reader);

    if (reader.skipIf(TokenType.assign)) {
      var expression = parseTuple(reader);
      return Assign(target: target, value: expression);
    }

    var filters = parseFilters(reader);
    var body = parseStatements(reader, endSet, true);
    return AssignBlock(target: target, filters: filters, body: body);
  }

  For parseFor(TokenReader reader) {
    const endIn = <(String, String?)>[(TokenType.name, 'in')];
    const endFor = <(String, String?)>[(TokenType.name, 'endfor')];
    const endForElse = <(String, String?)>[
      (TokenType.name, 'endfor'),
      (TokenType.name, 'else'),
    ];

    reader.expect(TokenType.name, 'for');

    var target = parseAssignTarget(reader, extraEndRules: endIn);

    if (target case Name(name: 'loop')) {
      fail("Can't assign to special loop variable in for-loop target.");
    }

    reader.expect(TokenType.name, 'in');

    var iterable = parseTuple(reader, withCondition: false);
    Expression? test;

    if (reader.skipIf(TokenType.name, 'if')) {
      test = parseExpression(reader);
    }

    var recursive = reader.skipIf(TokenType.name, 'recursive');
    var body = parseStatements(reader, endForElse);
    Node? orElse;

    if (reader.next().match(TokenType.name, 'else')) {
      orElse = parseStatements(reader, endFor, true);
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
    const endIf = <(String, String?)>[(TokenType.name, 'endif')];
    const endIfElseEndIf = <(String, String?)>[
      (TokenType.name, 'elif'),
      (TokenType.name, 'else'),
      (TokenType.name, 'endif'),
    ];

    reader.expect(TokenType.name, 'if');

    var test = parseExpression(reader, false);
    var body = parseStatements(reader, endIfElseEndIf);
    var root = If(test: test, body: body);
    var ifNodes = <If>[root];
    Token tag;

    while (true) {
      tag = reader.next();

      if (tag.match(TokenType.name, 'elif')) {
        var test = parseTuple(reader, withCondition: false);
        var body = parseStatements(reader, endIfElseEndIf);
        var elif = If(test: test, body: body);
        ifNodes.add(elif);
        continue;
      }

      break;
    }

    Node? orElse;

    if (tag.match(TokenType.name, 'else')) {
      orElse = parseStatements(reader, endIf, true);
    }

    var node = ifNodes.last.copyWith(orElse: orElse);

    for (var ifNode in ifNodes.reversed.skip(1)) {
      node = ifNode.copyWith(orElse: node);
    }

    return node;
  }

  With parseWith(TokenReader reader) {
    const endWith = <(String, String?)>[(TokenType.name, 'endwith')];

    reader.expect(TokenType.name, 'with');

    var targets = <Expression>[];
    var values = <Expression>[];

    while (reader.current.type != TokenType.blockEnd) {
      if (targets.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      var target = parseAssignTarget(reader, context: AssignContext.parameter);
      targets.add(target);
      reader.expect(TokenType.assign);
      values.add(parseExpression(reader));
    }

    var body = parseStatements(reader, endWith, true);
    return With(targets: targets, values: values, body: body);
  }

  Block parseBlock(TokenReader reader) {
    const endBlock = <(String, String?)>[(TokenType.name, 'endblock')];

    var token = reader.next();
    var name = reader.expect(TokenType.name);

    if (!blocks.add(name.value)) {
      fail("Block '${name.value}' defined twice.", reader.current.line);
    }

    var scoped = reader.skipIf(TokenType.name, 'scoped');

    if (reader.current.type == TokenType.sub) {
      fail('Use an underscore instead.', reader.current.line);
    }

    var required = reader.skipIf(TokenType.name, 'required');
    var body = parseStatements(reader, endBlock, true);

    if (required && (body is! Data || !body.isLeaf)) {
      fail(
        'Required blocks can only contain comments or whitespace.',
        token.line,
      );
    }

    var maybeName = reader.current;

    if (maybeName.type == TokenType.name) {
      if (maybeName.value != name.value) {
        fail("'${name.value}' expected, got ${maybeName.value}.");
      }

      reader.next();
    }

    return Block(
      name: name.value,
      scoped: scoped,
      required: required,
      body: body,
    );
  }

  Extends parseExtends(TokenReader reader) {
    var token = reader.expect(TokenType.name, 'extends');

    if (extendsNode != null) {
      fail('Extended multiple times.', token.line);
    }

    var template = parseExpression(reader);
    var node = Extends(template: template);
    extendsNode = node;
    return node;
  }

  bool parseImportContext(TokenReader reader, [bool defaultValue = true]) {
    const keywords = <(String, String?)>[
      (TokenType.name, 'with'),
      (TokenType.name, 'without'),
    ];

    var withContext = defaultValue;

    if (reader.current.matchAny(keywords) &&
        reader.look().match(TokenType.name, 'context')) {
      withContext = reader.current.value == 'with';
      reader.skip(2);
    }

    return withContext;
  }

  Include parseInclude(TokenReader reader) {
    reader.expect(TokenType.name, 'include');

    var template = parseExpression(reader);
    var ignoreMissing =
        reader.current.match(TokenType.name, 'ignore') &&
        reader.look().match(TokenType.name, 'missing');

    if (ignoreMissing) {
      reader.skip(2);
    }

    var withContext = parseImportContext(reader, true);
    return Include(
      template: template,
      ignoreMissing: ignoreMissing,
      withContext: withContext,
    );
  }

  Import parseImport(TokenReader reader) {
    reader.expect(TokenType.name, 'import');

    var template = parseExpression(reader);

    reader.expect(TokenType.name, 'as');

    var target = parseAssignName(reader);
    var withContext = parseImportContext(reader, false);
    return Import(
      template: template,
      target: target.name,
      withContext: withContext,
    );
  }

  FromImport parseFrom(TokenReader reader) {
    reader.expect(TokenType.name, 'from');

    var template = parseExpression(reader);

    reader.expect(TokenType.name, 'import');

    var names = <(String, String?)>[]; // target & alias
    var withContext = false;

    bool parseContext() {
      if (reader.current.value case 'with' || 'without'
          when reader.look().match(TokenType.name, 'context')) {
        withContext = reader.current.value == 'with';
        reader.skip(2);
        return true;
      } else {
        return false;
      }
    }

    while (true) {
      if (names.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.name) {
        if (parseContext()) {
          break;
        }

        var token = reader.current;
        var target = parseAssignName(reader);

        if (target.name.startsWith('_')) {
          fail(
            'Names starting with an underline can not be imported.',
            token.line,
          );
        }

        if (reader.skipIf(TokenType.name, 'as')) {
          var alias = parseAssignName(reader);
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
  (List<Expression>, List<(Expression, Expression)>) parseSignature(
    TokenReader reader,
  ) {
    var names = <Expression>[];
    var defaults = <Expression>[];

    reader.expect(TokenType.lParen);

    while (reader.current.type != TokenType.rParen) {
      if (names.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      var name = parseAssignName(reader, AssignContext.parameter);

      if (reader.skipIf(TokenType.assign)) {
        defaults.add(parseExpression(reader));
      } else if (defaults.isNotEmpty) {
        fail('Non-default argument follows default argument.');
      }

      names.add(name);
    }

    reader.expect(TokenType.rParen);

    var length = names.length - defaults.length;

    (Expression, Expression) generate(int i) {
      return (names[i + length], defaults[i]);
    }

    return (
      names.sublist(0, length),
      List<(Expression, Expression)>.generate(defaults.length, generate),
    );
  }

  CallBlock parseCallBlock(TokenReader reader) {
    const endCall = <(String, String?)>[(TokenType.name, 'endcall')];

    var token = reader.expect(TokenType.name, 'call');

    List<Expression> positional;
    List<(Expression, Expression)> named;

    if (reader.current.type == TokenType.lParen) {
      (positional, named) = parseSignature(reader);
    } else {
      positional = const <Expression>[];
      named = const <(Expression, Expression)>[];
    }

    var call = parseExpression(reader);

    if (call is! Call) {
      fail('Expected call.', token.line);
    }

    var name = call.value;

    if (name is! Name) {
      fail('Expected call macro name.', token.line);
    }

    var body = parseStatements(reader, endCall, true);
    var varargs = false, kwargs = false;

    for (var name in body.findAll<Name>()) {
      switch (name.name) {
        case 'varargs':
          varargs = true;
          break;
        case 'kwargs':
          kwargs = true;
          break;
        default:
      }
    }

    return CallBlock(
      call: call,
      varargs: varargs,
      kwargs: kwargs,
      positional: positional,
      named: named,
      body: body,
    );
  }

  FilterBlock parseFilterBlock(TokenReader reader) {
    const endFilter = <(String, String?)>[(TokenType.name, 'endfilter')];

    reader.expect(TokenType.name, 'filter');

    var filters = parseFilters(reader, true);
    var body = parseStatements(reader, endFilter, true);
    return FilterBlock(filters: filters, body: body);
  }

  Macro parseMacro(TokenReader reader) {
    const endMacro = <(String, String?)>[(TokenType.name, 'endmacro')];

    reader.expect(TokenType.name, 'macro');

    var name = parseAssignName(reader);
    var (positional, named) = parseSignature(reader);
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
      varargs: varargs,
      kwargs: kwargs,
      caller: caller,
      positional: positional,
      named: named,
      body: body,
    );
  }

  // TODO(parser): add parsePrint

  Name parseAssignName(
    TokenReader reader, [
    AssignContext context = AssignContext.store,
  ]) {
    var name = reader.expect(TokenType.name);
    return Name(name: name.value, context: context);
  }

  Expression parseAssignNameSpace(TokenReader reader) {
    var line = reader.current.line;

    if (reader.look().type == TokenType.dot) {
      var namespace = reader.expect(TokenType.name);
      reader.expect(TokenType.dot); // skip dot

      var attribute = reader.expect(TokenType.name);
      return NamespaceRef(name: namespace.value, attribute: attribute.value);
    }

    var name = parsePrimary(reader);

    if (name is! Name) {
      fail("Can't assign to $name.", line);
    }

    return name.copyWith(context: AssignContext.store);
  }

  Expression parseAssignTarget(
    TokenReader reader, {
    List<(String, String?)>? extraEndRules,
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

    if (target is Name) {
      return target.copyWith(context: context);
    }

    if (target is Tuple && target.values.any((value) => value is Name)) {
      return target.copyWith(
        values: <Expression>[
          for (var value in target.values.cast<Name>())
            value.copyWith(context: context),
        ],
      );
    }

    fail("Can't assign to $target.", line);
  }

  Do parseDo(TokenReader reader) {
    reader.expect(TokenType.name, 'do');

    return Do(value: parseTuple(reader));
  }

  Node parseTryCatch(TokenReader reader) {
    const endTry = <(String, String?)>[(TokenType.name, 'catch')];
    const endTryCatch = <(String, String?)>[(TokenType.name, 'endtry')];

    reader.expect(TokenType.name, 'try');

    var body = parseStatements(reader, endTry);
    reader.expect(TokenType.name, 'catch');

    var token = reader.current;
    Expression? name;

    if (token.type == TokenType.name) {
      name = parseAssignTarget(reader, withTuple: false);

      if (name is! Name) {
        fail("Can't assign to $name.", token.line);
      }
    }

    var catchBody = parseStatements(reader, endTryCatch);
    reader.expect(TokenType.name, 'endtry');
    return TryCatch(body: body, exception: name, catchBody: catchBody);
  }

  Expression parseExpression(TokenReader reader, [bool withCondition = true]) {
    if (withCondition) {
      return parseCondition(reader);
    }

    return parseTernary(reader);
  }

  Expression parseCondition(TokenReader reader, [bool withCondExpr = true]) {
    var value = parseTernary(reader);

    // Handle if-else syntax: trueValue if condition else falseValue
    while (reader.skipIf(TokenType.name, 'if')) {
      var condition = parseTernary(reader);

      if (reader.skipIf(TokenType.name, 'else')) {
        var orElse = parseCondition(reader);
        value = Condition(
          test: condition,
          trueValue: value,
          falseValue: orElse,
        );
      } else {
        value = Condition(test: condition, trueValue: value);
      }
    }

    return value;
  }

  Expression parseTernary(TokenReader reader) {
    var condition = parseOr(reader);

    // Handle ternary operator: condition ? trueValue : falseValue
    if (reader.skipIf(TokenType.question)) {
      var trueValue = parseTernary(reader);
      reader.expect(TokenType.colon);

      var falseValue = parseTernary(reader);
      return Condition(
        test: condition,
        trueValue: trueValue,
        falseValue: falseValue,
      );
    }

    return condition;
  }

  Expression parseOr(TokenReader reader) {
    var left = parseAnd(reader);

    while (reader.skipIf(TokenType.name, 'or') ||
        reader.skipIf(TokenType.nullCoalesce)) {
      var right = parseAnd(reader);
      left = Logical(operator: LogicalOperator.or, left: left, right: right);
    }

    return left;
  }

  Expression parseAnd(TokenReader reader) {
    var left = parseNot(reader);

    while (reader.skipIf(TokenType.name, 'and')) {
      var right = parseNot(reader);
      left = Logical(operator: LogicalOperator.and, left: left, right: right);
    }

    return left;
  }

  Expression parseNot(TokenReader reader) {
    if (reader.current.match(TokenType.name, 'not')) {
      reader.next();

      var value = parseNot(reader);
      return Unary(operator: UnaryOperator.not, value: value);
    }

    return parseCompare(reader);
  }

  Expression parseCompare(TokenReader reader) {
    const operators = <(String, String?)>[
      (TokenType.eq, null),
      (TokenType.ne, null),
      (TokenType.lt, null),
      (TokenType.ltEq, null),
      (TokenType.gt, null),
      (TokenType.gtEq, null),
    ];

    var value = parseMath1(reader);
    var operands = <Operand>[];

    outer:
    while (true) {
      CompareOperator operator;

      if (reader.current.matchAny(operators)) {
        var token = reader.current;

        reader.next();

        operator = CompareOperator.parse(token.type);
      } else if (reader.skipIf(TokenType.name, 'in')) {
        operator = CompareOperator.contains;
      } else if (reader.current.match(TokenType.name, 'not') &&
          reader.look().match(TokenType.name, 'in')) {
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
        case TokenType.add:
          reader.next();
          operator = ScalarOperator.plus;
          break;

        case TokenType.sub:
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

    while (reader.current.type == TokenType.tilde) {
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
        case TokenType.mul:
          reader.next();

          operator = ScalarOperator.multiple;
          break;

        case TokenType.div:
          reader.next();

          operator = ScalarOperator.division;
          break;

        case TokenType.floorDiv:
          reader.next();

          operator = ScalarOperator.floorDivision;
          break;

        case TokenType.mod:
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

    while (reader.current.type == TokenType.pow) {
      reader.next();

      var right = parseUnary(reader);
      left = Scalar(operator: ScalarOperator.power, left: left, right: right);
    }

    return left;
  }

  Expression parseUnary(TokenReader reader, {bool withFilter = true}) {
    Expression value;

    switch (reader.current.type) {
      case TokenType.add:
        reader.next();

        value = parseUnary(reader, withFilter: false);
        value = Unary(operator: UnaryOperator.plus, value: value);
        break;

      case TokenType.sub:
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
      case TokenType.name:
        switch (current.value) {
          case 'false':
            expression = const Constant(value: false);
            break;

          case 'true':
            expression = const Constant(value: true);
            break;

          case 'null':
            expression = const Constant(value: null);
            break;

          default:
            expression = Name(name: current.value);
        }

        reader.next();
        break;

      case TokenType.string:
        var buffer = StringBuffer(current.value);

        reader.next();

        while (reader.current.type == TokenType.string) {
          buffer.write(reader.current.value);
          reader.next();
        }

        var value = buffer.toString();
        // TODO(parser): replace all escaped characters
        value = value.replaceAll(r'\\r', '\r').replaceAll(r'\\n', '\n');
        expression = Constant(value: value);
        break;

      case TokenType.integer:
      case TokenType.float:
        expression = Constant(value: num.parse(current.value));

        reader.next();
        break;

      case TokenType.lParen:
        reader.next();

        expression = parseTuple(reader, explicitParentheses: true);

        reader.expect(TokenType.rParen);
        break;

      case TokenType.lBracket:
        expression = parseList(reader);
        break;

      case TokenType.lBrace:
        expression = parseDict(reader);
        break;

      default:
        fail('Unexpected ${describeToken(current)}.', current.line);
    }

    return expression;
  }

  Expression parseTuple(
    TokenReader reader, {
    bool simplified = false,
    bool withCondition = true,
    List<(String, String?)>? extraEndRules,
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
        reader.expect(TokenType.comma);
      }

      if (isTupleEnd(reader, extraEndRules)) {
        break;
      }

      values.add(parse(reader));

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
        var current = reader.current;
        fail(
          'Expected an expression, got ${describeToken(current)}.',
          current.line,
        );
      }
    }

    return Tuple(values: values);
  }

  Expression parseList(TokenReader reader) {
    reader.expect(TokenType.lBracket);

    var values = <Expression>[];

    while (reader.current.type != TokenType.rBracket) {
      if (values.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBracket) {
        break;
      }

      values.add(parseExpression(reader));
    }

    reader.expect(TokenType.rBracket);

    return Array(values: values);
  }

  Expression parseDict(TokenReader reader) {
    reader.expect(TokenType.lBrace);

    var pairs = <Pair>[];

    while (reader.current.type != TokenType.rBrace) {
      if (pairs.isNotEmpty) {
        reader.expect(TokenType.comma);
      }

      if (reader.current.type == TokenType.rBrace) {
        break;
      }

      var key = parseExpression(reader);

      reader.expect(TokenType.colon);

      var value = parseExpression(reader);
      pairs.add((key: key, value: value));
    }

    reader.expect(TokenType.rBrace);

    return Dict(pairs: pairs);
  }

  Expression parsePostfix(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.type case TokenType.dot || TokenType.lBracket) {
        expression = parseSubscript(reader, expression);
      } else if (reader.current.type == TokenType.lParen) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  // TODO(parser): check if filters and tests exist, else throw TemplateAssertionError
  Expression parseFilterExpression(TokenReader reader, Expression expression) {
    while (true) {
      if (reader.current.type == TokenType.pipe) {
        expression = parseFilter(reader, expression);
      } else if (reader.current.match(TokenType.name, 'is')) {
        expression = parseTest(reader, expression);
      } else if (reader.current.type == TokenType.lParen) {
        expression = parseCall(reader, expression);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression parseSubscript(TokenReader reader, Expression value) {
    var token = reader.next();

    if (token.type == TokenType.dot) {
      var attributeToken = reader.next();

      if (attributeToken.type == TokenType.name) {
        return Attribute(attribute: attributeToken.value, value: value);
      }

      if (attributeToken.type != TokenType.integer) {
        fail('Expected name or number.', attributeToken.line);
      }

      var key = Constant(value: int.parse(attributeToken.value));
      return Item(key: key, value: value);
    }

    if (token.type == TokenType.lBracket) {
      if (reader.nextIf(TokenType.colon) != null) {
        var stop = parseExpression(reader);
        reader.expect(TokenType.rBracket);
        return Slice(start: null, stop: stop, value: value);
      }
      var key = parseExpression(reader);
      if (reader.nextIf(TokenType.colon) != null) {
        if (reader.skipIf(TokenType.rBracket)) {
          return Slice(start: key, stop: null, value: value);
        } else {
          var stop = parseExpression(reader);
          reader.expect(TokenType.rBracket);
          return Slice(start: key, stop: stop, value: value);
        }
      } else {
        reader.expect(TokenType.rBracket);
        return Item(key: key, value: value);
      }
    }

    fail('Expected subscript expression.', token.line);
  }

  Calling parseCalling(TokenReader reader) {
    var token = reader.expect(TokenType.lParen);
    var arguments = <Expression>[];
    var keywords = <Keyword>[];
    var requireComma = false;

    void ensure(bool ensure) {
      if (!ensure) {
        fail('Invalid syntax for function call expression.', token.line);
      }
    }

    while (reader.current.type != TokenType.rParen) {
      if (requireComma) {
        reader.expect(TokenType.comma);

        if (reader.current.type == TokenType.rParen) {
          break;
        }
      }

      if (reader.current.type == TokenType.name &&
          reader.look().type == TokenType.assign) {
        var key = reader.current.value;

        reader.skip(2);

        var value = parseExpression(reader);

        if (key == 'default') {
          key = 'defaultValue';
        }

        keywords.add((key: key, value: value));
      } else {
        ensure(keywords.isEmpty);
        arguments.add(parseExpression(reader));
      }

      requireComma = true;
    }

    reader.expect(TokenType.rParen);

    return Calling(arguments: arguments, keywords: keywords);
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

    while (reader.current.type == TokenType.pipe || startInline) {
      if (!startInline) {
        reader.next();
      }

      var token = reader.expect(TokenType.name);
      var filter = Filter(name: token.value);

      if (reader.current.type == TokenType.lParen) {
        var calling = parseCalling(reader);
        filter = filter.copyWith(calling: calling);
      }

      filters.add(filter);
      startInline = false;
    }

    return filters;
  }

  Expression parseTest(TokenReader reader, Expression expression) {
    const allow = <(String, String?)>[
      (TokenType.name, null),
      (TokenType.string, null),
      (TokenType.integer, null),
      (TokenType.float, null),
      (TokenType.lBracket, null),
      (TokenType.lBrace, null),
    ];
    const deny = <(String, String?)>[
      (TokenType.name, 'else'),
      (TokenType.name, 'or'),
      (TokenType.name, 'and'),
    ];

    reader.expect(TokenType.name, 'is');

    var negated = false;

    if (reader.current.match(TokenType.name, 'not')) {
      reader.next();

      negated = true;
    }

    var token = reader.expect(TokenType.name);
    var current = reader.current;

    Calling calling;

    if (current.type == TokenType.lParen) {
      calling = parseCalling(reader);

      var arguments = <Expression>[expression, ...calling.arguments];
      calling = calling.copyWith(arguments: arguments);
    } else if (current.matchAny(allow) && !current.matchAny(deny)) {
      if (current.match(TokenType.name, 'is')) {
        fail('You cannot chain multiple tests with is.');
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

  Node scan(Iterable<Token> tokens) {
    var reader = TokenReader(tokens);
    var nodes = subParse(reader);
    return Output(nodes: nodes);
  }

  List<Node> subParse(
    TokenReader reader, {
    List<(String, String?)>? endTokens,
  }) {
    var nodes = <Node>[];

    if (endTokens != null) {
      endTokensStack.add(endTokens);
    }

    try {
      while (reader.current.type != TokenType.eof) {
        var token = reader.current;

        switch (token.type) {
          case TokenType.data:
            nodes.add(Data(data: token.value));

            reader.next();
            break;

          case TokenType.variableBegin:
            reader.next();

            nodes.add(Interpolation(value: parseTuple(reader)));

            reader.expect(TokenType.variableEnd);
            break;

          case TokenType.blockBegin:
            reader.next();

            if (endTokens != null && reader.current.matchAny(endTokens)) {
              return nodes;
            }

            var node = parseStatement(reader);

            if (extendsNode != null && node is! Block) {
              fill('');
            }

            nodes.add(node);

            reader.expect(TokenType.blockEnd);
            break;

          default:
            assert(false);
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
    return TemplateNode(body: scan(tokens));
  }
}
