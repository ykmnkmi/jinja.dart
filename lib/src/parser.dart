import 'package:string_scanner/string_scanner.dart';

import 'env.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'utils.dart';

class Parser {
  Parser(this.env)
      : _stmtOpen = RegExp(env.stmtOpen + _spaceReg.pattern),
        _varOpen = RegExp(env.varOpen + _spaceReg.pattern),
        _commentOpen = RegExp(env.commentOpen + _spaceReg.pattern),
        _stmtClose = RegExp(_spaceReg.pattern + env.stmtClose),
        _varClose = RegExp(_spaceReg.pattern + env.varClose),
        _commentClose = RegExp(_spaceReg.pattern + env.commentClose),
        _equalityReg = RegExp(_spaceReg.pattern +
            r'(==|!=)(?![' +
            env.stmtClose[0] +
            env.varClose[0] +
            '])' +
            _spaceReg.pattern),
        _relationalReg = RegExp(_spaceReg.pattern +
            r'(>=|>|<=|<)(?![' +
            env.stmtClose[0] +
            env.varClose[0] +
            '])' +
            _spaceReg.pattern),
        _additiveReg = RegExp(_spaceReg.pattern +
            r'(\+|-)(?![' +
            env.stmtClose[0] +
            env.varClose[0] +
            '])' +
            _spaceReg.pattern),
        _multiplicativeReg = RegExp(_spaceReg.pattern +
            r'(\/\/|\*\*|\*|\/|%)(?![' +
            env.stmtClose[0] +
            env.varClose[0] +
            '])' +
            _spaceReg.pattern);

  final Environment env;

  final RegExp _stmtOpen;
  final RegExp _varOpen;
  final RegExp _commentOpen;

  final RegExp _stmtClose;
  final RegExp _varClose;
  final RegExp _commentClose;

  final RegExp _equalityReg;
  final RegExp _relationalReg;
  final RegExp _additiveReg;
  final RegExp _multiplicativeReg;

  final _buffer = StringBuffer();
  final _nodes = <Node>[];

  Node parse(String source, {path}) {
    _buffer.clear();
    _nodes.clear();

    final scanner = SpanScanner(source, sourceUrl: path);
    try {
      while (!scanner.isDone) {
        if (scanner.matches(
            RegExp([env.stmtOpen, env.varOpen, env.commentOpen].join('|')))) {
          _flush();
          if (scanner.scan(_stmtOpen))
            _parseStmt(scanner);
          else if (scanner.scan(_varOpen))
            _parseVar(scanner);
          else if (scanner.scan(_commentOpen))
            _skipComment(scanner);
          else
            scanner.error('Can not match');
        } else
          _buffer.writeCharCode(scanner.readChar());
      }
      _flush();
      if (_nodes.isEmpty) return const Literal<String>('');
      final first = _nodes.first;
      if (first is Tag && first.tag == 'extends') {
        _nodes.removeAt(0);
        if (!_nodes.every((node) => node is! Extend)) throw Exception();
        return Extend(
            first.arg,
            _nodes
                .whereType<Block>()
                .toList()
                .asMap()
                .map((_, block) => MapEntry(block.name, block)));
      }
      return Output.orNode(_nodes);
    } catch (e) {
      return Literal<String>(e.toString());
    }
  }

  void _parseStmt(SpanScanner scanner) {
    scanner.expect(_identifierReg, name: 'tag');
    var tag = scanner.lastMatch[1];
    scanner.expect(_spacePlusReg, name: 'space after tag');
    Node node;
    if (!tag.startsWith('end')) {
      switch (tag) {
        case 'else':
          node = Tag(tag);
          break;
        case 'for':
          scanner.expect(_identifierReg);
          final target = scanner.lastMatch[1];
          if (target == 'in')
            scanner.error('"in" can\'t be variable identifier');
          scanner.expect(_inReg);
          final iter = _parsePrimaryExpr(scanner);
          if (iter == null) scanner.error('"for" iterable expression expected');
          var isRecursive = false;
          if (scanner.scan(RegExp(_spacePlusReg.pattern + 'recursive')))
            isRecursive = true;
          if (scanner.scan(_ifReg)) {
            var test = _parseExpr(scanner);
            if (test == null) scanner.error('"for" test expression');
            if (test is! Test) test = Test('defined', test);
            node = Tag(tag, target, iter, isRecursive, test);
          } else
            node = Tag(tag, target, iter, isRecursive);
          break;
        case 'elif':
        case 'if':
          var test = _parseExpr(scanner);
          if (test is! Test) test = Test('defined', test);
          node = Tag(tag, test);
          break;
        case 'set':
          scanner.expect(_identifierReg, name: 'variable name to set');
          final name = scanner.lastMatch[1];
          if (scanner.scan(_equalSignReg)) {
            final variable = _parseExpr(scanner);
            node = Set(name, variable);
          }
          break;
        case 'extends':
          if (_nodes.isNotEmpty && _nodes.first is Extend)
            scanner.error('"extends" can be only one and first');
          final parent = _parsePrimaryExpr(scanner);
          if (parent == null) scanner.error('Expected template name');
          node = Tag(tag, parent);
          break;
        case 'block':
          scanner.expect(_identifierReg, name: 'block name');
          final name = scanner.lastMatch[1];
          node = Tag(tag, name);
          break;
        default:
          scanner.error('Unimplemented tag: $tag');
      }
    } else {
      tag = tag.substring(3);
      switch (tag) {
        case 'block':
          node = _parseBlockStmt();
          break;
        case 'for':
          node = _parseForStmt();
          break;
        case 'if':
          node = _parseIfStmt();
          break;
        case 'set':
          node = _parseSetStmt();
          break;
        default:
          scanner.error('Unimplemented tag: $tag');
      }
    }
    scanner.expect(RegExp(_spaceReg.pattern + env.stmtClose));
    _nodes.add(node);
  }

  Node _parseForStmt() {
    String target;
    Node body, orElse;
    Expression iter;
    bool isRecursive;
    Test test;
    final nodes = <Node>[];
    while (_nodes.isNotEmpty) {
      final node = _nodes.removeLast();
      if (node is Tag) if (node.tag == 'else') {
        orElse = Output.orNode(nodes.reversed.toList());
        nodes.clear();
      } else if (node.tag == 'for') {
        target = node.arg;
        iter = node.arg2;
        isRecursive = node.arg3;
        body = Output.orNode(nodes.reversed.toList());
        test = node.arg4;
        nodes.clear();
        break;
      } else
        throw Exception(node.toString());
      else
        nodes.add(node);
    }
    return For(target, iter, body,
        isRecursive: isRecursive, test: test, orElse: orElse);
  }

  Node _parseIfStmt() {
    Test test;
    Node body, orElse;
    final nodes = <Node>[];
    while (_nodes.isNotEmpty) {
      final node = _nodes.removeLast();
      if (node is Tag) if (node.tag == 'else') {
        orElse = Output.orNode(nodes.reversed.toList());
        nodes.clear();
      } else if (node.tag == 'elif') {
        test = node.arg;
        body = Output.orNode(nodes.reversed.toList());
        nodes.clear();
        orElse = If(test, body, orElse);
      } else if (node.tag == 'if') {
        test = node.arg;
        body = Output.orNode(nodes.reversed.toList());
        nodes.clear();
        break;
      } else
        throw Exception(node.toString());
      else
        nodes.add(node);
    }
    return If(test, body, orElse);
  }

  Node _parseSetStmt() {
    return null;
  }

  Node _parseBlockStmt() {
    String name;
    Node body;
    final nodes = <Node>[];
    while (_nodes.isNotEmpty) {
      final node = _nodes.removeLast();
      if (node is Tag && node.tag == 'block') {
        name = node.arg;
        body = Output.orNode(nodes.reversed.toList());
        nodes.clear();
        break;
      } else
        nodes.add(node);
    }
    return Block(name, body);
  }

  void _parseVar(SpanScanner scanner) {
    final expr = _parseExpr(scanner);
    if (expr == null) scanner.error('Expected expression');
    _nodes.add(expr);
    scanner.expect(RegExp(_spaceReg.pattern + env.varClose),
        name: 'double curly');
  }

  void _skipComment(SpanScanner scanner) {
    while (!scanner.scan(RegExp(_spaceReg.pattern + env.commentClose)))
      scanner.position++;
  }

  void _flush() {
    if (_buffer.isNotEmpty) {
      final body = _buffer.toString();
      _buffer.clear();
      _nodes.add(Literal<String>(body));
    }
  }

  Expression _parseExpr(SpanScanner scanner) {
    Expression expr;
    if (!isNull(expr = _parseLogicalOrExpr(scanner))) {
      while (true) {
        if (scanner.scan(_pipeReg)) {
          scanner.expect(_identifierReg, name: 'pipe identifier');
          final name = scanner.lastMatch[1];
          if (scanner.scan(_lParenBracketReg)) {
            if (scanner.scan('*')) {
              scanner.expect(_identifierReg);
              final name = scanner.lastMatch[1];
              final variable = Variable(name);
              expr = CallSpread(expr, variable);
            } else {
              final params = _parseParams(scanner);
              expr =
                  Filter(name, expr, args: params.args, kwargs: params.kwargs);
            }
            scanner.expect(_rParenBracketReg, name: 'right paren bracket');
          } else
            expr = Filter(name, expr);
        } else
          break;
      }
    }
    return expr;
  }

  List<Expression> _parseExprList(SpanScanner scanner) {
    Expression expr;
    final list = <Expression>[];
    do {
      expr = _parseExpr(scanner);
      if (expr != null) list.add(expr);
    } while (scanner.scan(_commaReg));
    if (list.isNotEmpty) return list;
    return null;
  }

  // Expression _parseConditionalExpr(SpanScanner scanner) {
  //   Expression expr;
  //   if (!isNull(expr = parseLogicalOrExpr(scanner))) {
  //     if (scanner.scan(_ifReg)) {
  //       Expression condition;
  //       if (isNull(condition = parseExpr(scanner)))
  //         scanner.error('Expression');
  //       if (scanner.scan(_isReg)) {
  //         bool isNot = scanner.scan(_notReg);
  //         scanner.expect(_identifierReg);
  //         String name = scanner.lastMatch[1];
  //         if (scanner.scan(_lParenReg)) {
  //           List<Expression> args = parseExprList(scanner);
  //           if (isNull(expr)) scanner.error('expression expected');
  //           scanner.expect(_rParenReg);
  //           Expression test = Test.name(name, expr, args: args);
  //           condition = isNot ? Not(test) : test;
  //         }
  //         scanner.scan(_spaceReg);
  //         if (!scanner.matches(_elseReg)) {
  //           Expression arg = parsePrimaryExpr(scanner);
  //           condition = isNull(arg)
  //               ? Test.name(name, expr)
  //               : Test.name(name, expr, args: [arg]);
  //         }
  //       } else if (scanner.scan(_notInReg)) {
  //         bool isNot = scanner.lastMatch[2] == 'not';
  //         Expression seq = parsePrimaryExpr(scanner);
  //         if (isNull(seq)) scanner.error('Primary expression');
  //         Expression test = Test.name('in', expr, args: [seq]);
  //         condition = isNot ? Not(test) : test;
  //       }
  //       scanner.expect(_elseReg);
  //       Expression orElse;
  //       if (isNull(orElse = parseExpr(scanner)))
  //         scanner.error('Expression expected');
  //       return Conditional(expr, condition, orElse);
  //     }
  //   }
  //   return expr;
  // }

  Expression _parseLogicalOrExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseLogicalAndExpr(scanner))) {
      while (scanner.scan(_logicalOrReg)) {
        Expression right;
        if (isNull(right = _parseLogicalAndExpr(scanner)))
          scanner.error('Expression expected');
        left = Or(left, right);
      }
      return left;
    }
    return left;
  }

  Expression _parseLogicalAndExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseTestExpression(scanner))) {
      Expression right;
      while (scanner.scan(_logicalAndReg)) {
        if (isNull(right = _parseTestExpression(scanner)))
          scanner.error('Equality expression expected');
        left = And(left, right);
      }
      return left;
    }
    return left;
  }

  Expression _parseTestExpression(SpanScanner scanner) {
    Expression expr;
    if (!isNull(expr = _parseEqualityExpr(scanner))) {
      if (scanner.scan(_inReg)) {
        final isNot = scanner.lastMatch[1] != null;
        final seq = _parseExpr(scanner);
        if (seq == null) scanner.error('Expected expression');
        expr = Test('in', expr, args: [seq]);
        if (isNot) expr = Not(expr);
      } else if (scanner.scan(_isReg)) {
        final isNot = scanner.lastMatch[1] != null;
        scanner.expect(_identifierReg, name: 'identifier');
        final name = scanner.lastMatch[1];
        scanner.expect(_spacePlusReg);
        final arg = _parsePrimaryExpr(scanner);
        if (arg != null)
          expr = Test(name, expr, args: [arg]);
        else
          expr = Test(name, expr);
        if (isNot) expr = Not(expr);
      }
    }
    return expr;
  }

  Expression _parseEqualityExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseRelationalExpr(scanner))) {
      if (scanner.scan(_equalityReg)) {
        final op = scanner.lastMatch[1];
        Expression right;
        if (isNull(right = _parseRelationalExpr(scanner)))
          scanner.error('Relational expression expected');
        switch (op) {
          case '==':
            return Equal(left, right);
          case '!=':
            return NotEqual(left, right);
        }
      }
    }
    return left;
  }

  Expression _parseRelationalExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseAdditiveExpr(scanner))) {
      if (scanner.scan(_relationalReg)) {
        Expression right;
        final op = scanner.lastMatch[1];
        if (isNull(right = _parseAdditiveExpr(scanner)))
          scanner.error('Additive expression expected');
        switch (op) {
          case '>=':
            return GreaterOrEqual(left, right);
          case '>':
            return Greater(left, right);
          case '<':
            return Less(left, right);
          case '<=':
            return LessOrEqual(left, right);
        }
      }
    }
    return left;
  }

  Expression _parseAdditiveExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseMultiplicativeExpr(scanner))) {
      Expression right;
      String op;
      while (scanner.scan(_additiveReg)) {
        op = scanner.lastMatch[1];
        if (isNull(right = _parseMultiplicativeExpr(scanner)))
          scanner.error('Multiplicative expression expected');
        switch (op) {
          case '+':
            left = Add(left, right);
            break;
          case '-':
            left = Sub(left, right);
            break;
        }
      }
    }
    return left;
  }

  Expression _parseMultiplicativeExpr(SpanScanner scanner) {
    Expression left;
    if (!isNull(left = _parseUnaryExpression(scanner))) {
      Expression right;
      String op;
      while (scanner.scan(_multiplicativeReg)) {
        op = scanner.lastMatch[1];
        if (isNull(right = _parseUnaryExpression(scanner)))
          scanner.error('Unary expression expected');
        switch (op) {
          case '*':
            left = Mul(left, right);
            break;
          case '/':
            left = Div(left, right);
            break;
          case '%':
            left = Mod(left, right);
            break;
          case '//':
            left = FloorDiv(left, right);
            break;
          case '**':
            left = Pow(left, right);
            break;
        }
      }
      return left;
    }
    return left;
  }

  Expression _parseUnaryExpression(SpanScanner scanner) {
    Expression expr;
    if (scanner.scan(_unaryReg) || scanner.scan(_notReg)) {
      final op = scanner.lastMatch[1];
      if (isNull(expr = _parsePostfixExpr(scanner)))
        scanner.error('eexpression expected');
      switch (op) {
        case 'not':
          return Not(expr);
        case '-':
          return Neg(expr);
        case '+':
          return Pos(expr);
      }
    }
    if (!isNull(expr = _parsePostfixExpr(scanner))) return expr;
    return null;
  }

  Expression _parsePostfixExpr(SpanScanner scanner) {
    Expression expr;
    if (!isNull(expr = _parsePrimaryExpr(scanner))) {
      while (true) {
        if (scanner.scan(_lSquareBracketReg)) {
          final key = _parseExpr(scanner);
          if (isNull(key)) scanner.error('key expression expected');
          if (scanner.scan(_colonReg)) {
            final endKey = _parseExpr(scanner);
            if (key is Literal<num> && endKey is Literal<num>)
              expr = Filter('sublist', expr, args: [key, endKey]);
            else
              scanner.error('slice args must be num');
          } else {
            expr = Key(key, expr);
          }
          scanner.expect(_rSquareBracketReg, name: ']');
        } else if (scanner.scan(_fieldReg))
          expr = Field(scanner.lastMatch[1], expr);
        else if (scanner.scan(_lParenBracketReg)) {
          if (scanner.scan('*')) {
            scanner.expect(_identifierReg);
            final name = scanner.lastMatch[1];
            final variable = Variable(name);
            expr = CallSpread(expr, variable);
          } else {
            final params = _parseParams(scanner);
            expr = Call(expr, args: params.args, kwargs: params.kwargs);
          }
          scanner.expect(_rParenBracketReg, name: 'right paren bracket');
        } else
          break;
      }
      return expr;
    }
    return expr;
  }

  ParsedParams _parseParams(SpanScanner scanner) {
    Expression expr, expr2;
    final args = <Expression>[];
    final kwargs = <String, Expression>{};
    var inKeys = false;
    do {
      if (!isNull(expr = _parseExpr(scanner))) if (scanner
          .scan(_equalSignReg)) {
        inKeys = true;
        if (isNull(expr2 = _parseExpr(scanner)))
          scanner.error('Expression expected');
        if (expr is Variable)
          kwargs[expr.name] = expr2;
        else
          scanner.error('Valid key expected');
      } else
        args.add(expr);
      if (args.isNotEmpty && inKeys) scanner.error('Key value entry expected');
    } while (scanner.scan(_commaReg));
    return ParsedParams(args, kwargs);
  }

  Expression _parsePrimaryExpr(SpanScanner scanner) {
    Expression expr;
    if (!isNull(expr = _parseCompoundLiteral(scanner))) return expr;
    if (scanner.scan(_lParenBracketReg)) {
      final exprList = _parseExprList(scanner);
      if (exprList.length == 1)
        expr = exprList.first;
      else
        expr = ExpressionList(exprList);
      scanner.expect(_rParenBracketReg, name: 'right paren bracket');
      return expr;
    }
    if (!isNull(expr = _parseLiteral(scanner))) return expr;
    if (scanner.scan(_identifierReg)) return Variable(scanner.lastMatch[1]);
    return null;
  }

  Literal _parseLiteral(SpanScanner scanner) {
    if (scanner.scan('none')) return const Literal<Undefined>(Undefined());
    if (scanner.scan('false')) return const Literal<bool>(false);
    if (scanner.scan('true')) return const Literal<bool>(true);
    if (scanner.scan(_digitReg)) {
      var rawNum = scanner.lastMatch[1];
      if (scanner.scan(_fractionalReg)) rawNum += scanner.lastMatch[1];
      return Literal<num>(num.tryParse(rawNum));
    }
    if (scanner.scan(_stringStartReg)) {
      String body;
      switch (scanner.lastMatch[1]) {
        case '"':
          scanner.expect(_stringContentDQReg,
              name: 'optional string content and double quote');
          body = scanner.lastMatch[1];
          break;
        case "'":
          scanner.expect(_stringContentSQReg,
              name: 'optional string content and single quote');
          body = scanner.lastMatch[1];
          break;
      }
      return Literal<String>(body);
    }
    return null;
  }

  Expression _parseCompoundLiteral(SpanScanner scanner) {
    Expression expr;
    if (!isNull(expr = _parseListLiteral(scanner))) return expr;
    if (!isNull(expr = _parseMapLiteral(scanner))) return expr;
    return null;
  }

  Expression _parseListLiteral(SpanScanner scanner) {
    Expression literal;
    if (scanner.scan(_lSquareBracketReg)) {
      final list = _parseExprList(scanner);
      if (!isNull(list)) {
        if (list.every((expr) => expr is Literal))
          literal = Literal<List>(
              list.cast<Literal>().map((l) => l.value).toList(growable: false));
        else
          literal = ExpressionList(list);
      } else
        literal = const Literal<List>([]);
      scanner.expect(_rSquareBracketReg, name: 'right square bracket');
      return literal;
    }
    return null;
  }

  Expression _parseMapLiteral(SpanScanner scanner) {
    if (scanner.scan(_lCurlyBracketReg)) {
      final keys = <String>[];
      final values = <Expression>[];
      String key;
      Expression expr;
      do {
        if (scanner.scan(_stringStartReg)) {
          switch (scanner.lastMatch[1]) {
            case '"':
              scanner.expect(_stringContentDQReg,
                  name: 'optional string content and double quote');
              key = scanner.lastMatch[1];
              break;
            case "'":
              scanner.expect(_stringContentSQReg,
                  name: 'optional string content and single quote');
              key = scanner.lastMatch[1];
              break;
          }
          scanner.expect(_colonReg, name: 'Colon');
          if (isNull(expr = _parseExpr(scanner)))
            scanner.error('Expression expected');
          keys.add(key);
          values.add(expr);
        } else
          break;
      } while (scanner.scan(_commaReg));
      scanner.expect(_rCurlyBracketReg, name: 'Right curly bracket');
      return ExpressionMap(Map<String, Expression>.fromIterables(keys, values));
    }
    return null;
  }
}

class ParsedParams {
  const ParsedParams(this.args, this.kwargs);

  final List<Expression> args;
  final Map<String, Expression> kwargs;
}

// final _elseReg = RegExp(r'[ \t]+else[ \t]+');
final _ifReg = RegExp(r'[ \t]+if[ \t]+');
// final _concatReg = RegExp(r'[ \t]*~[ \t]*');
final _isReg = RegExp(r'[ \t]+is([ \t]+not)*[ \t]+');
final _inReg = RegExp(r'[ \t]+(not[ \t]+)*in[ \t]+');
final _pipeReg = RegExp(r'[ \t]*\|[ \t]*');
final _equalSignReg = RegExp(r'[ \t]*=[ \t]*');
final _commaReg = RegExp(r'[ \t]*,[ \t]*');
final _logicalOrReg = RegExp(r'[ \t]+or[ \t]+');
final _logicalAndReg = RegExp(r'[ \t]+and[ \t]+');
final _unaryReg = RegExp(r'(-|\+)');
final _notReg = RegExp(r'(not)[ \t]+');
final _colonReg = RegExp(r'[ \t]*\:[ \t]*');
final _rCurlyBracketReg = RegExp(r'[ \t]*\}');
final _lCurlyBracketReg = RegExp(r'\{[ \t]*');
final _rSquareBracketReg = RegExp(r'[ \t]*\]');
final _lSquareBracketReg = RegExp(r'\[[ \t]*');
final _rParenBracketReg = RegExp(r'[ \t]*\)');
final _lParenBracketReg = RegExp(r'\([ \t]*');
final _fieldReg = RegExp(r'\.(([a-zA-Z_][a-zA-Z0-9_]*))');
final _stringContentDQReg = RegExp(r'([^"\n\r]*|\\[\n\r]*)"');
final _stringContentSQReg = RegExp(r"([^'\n\r]*|\\[\n\r]*)'");
final _stringStartReg = RegExp('''(\\'|\\")''');
final _fractionalReg = RegExp(r'(\.\d+)');
final _digitReg = RegExp(r'(\d+)');
final _identifierReg = RegExp(r'([a-zA-Z][a-zA-Z0-9_]*)');
final _spacePlusReg = RegExp(r'[ \t]+');
final _spaceReg = RegExp(r'[ \t]*');
