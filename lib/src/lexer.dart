import 'package:jinja/src/environment.dart';
import 'package:string_scanner/string_scanner.dart';

enum TokenType {
  // core
  blockBegin,
  blockEnd,
  variableStart,
  variableEnd,
  commentStart,
  commentEnd,

  // base tokens
  data,
  space,
  newLine,
  eof,
}

class Token {
  factory Token.data(int line, String value) =>
      Token(line, TokenType.data, value);

  factory Token.space(int line, String value) =>
      Token(line, TokenType.space, value);

  factory Token.newLine(int line) => Token(line, TokenType.space, '\n');

  factory Token.eof(int line, String value) =>
      Token(line, TokenType.eof, value);

  const Token(this.line, this.type, [this.value]);

  final int line;
  final TokenType type;
  final String? value;

  @override
  String toString() => '$type${value == null ? '' : '|$value'}';
}

final RegExp spaceRe = RegExp('[ \t]+');
final RegExp newLineRe = RegExp('\n');

class Lexer {
  Lexer(Environment environment)
      : blockStart =
            RegExp(RegExp.escape(environment.blockStart), unicode: true),
        blockEnd = RegExp(RegExp.escape(environment.blockEnd), unicode: true),
        variableStart =
            RegExp(RegExp.escape(environment.variableStart), unicode: true),
        variableEnd =
            RegExp(RegExp.escape(environment.variableEnd), unicode: true),
        commentStart =
            RegExp(RegExp.escape(environment.commentStart), unicode: true),
        commentEnd =
            RegExp(RegExp.escape(environment.commentEnd), unicode: true),
        rules = <Rule>[] {
    final tagRules = <List<Object>>[
      // comment
      <Object>[
        environment.commentStart,
        Rule.scan(commentStart,
            (scanner) => Token(scanner.line, TokenType.commentStart))
      ],
      <Object>[
        environment.commentEnd,
        Rule.scan(
            commentEnd, (scanner) => Token(scanner.line, TokenType.commentEnd))
      ],
      // block
      <Object>[
        environment.blockStart,
        Rule.scan(
            blockStart, (scanner) => Token(scanner.line, TokenType.blockBegin))
      ],
      <Object>[
        environment.blockEnd,
        Rule.scan(
            blockEnd, (scanner) => Token(scanner.line, TokenType.blockEnd))
      ],
      // variable
      <Object>[
        environment.variableStart,
        Rule.scan(variableStart,
            (scanner) => Token(scanner.line, TokenType.variableStart))
      ],
      <Object>[
        environment.variableEnd,
        Rule.scan(variableEnd,
            (scanner) => Token(scanner.line, TokenType.variableEnd))
      ],
    ]..sort((a, b) => (b[0] as String).compareTo(a[0] as String));

    rules
      ..addAll(tagRules.map<Rule>((tagRule) => tagRule[1] as Rule))
      ..add(Rule.scan(spaceRe,
          (scanner) => Token.space(scanner.line, scanner.lastMatch![0]!)))
      ..add(Rule.scan(newLineRe, (scanner) => Token.newLine(scanner.line)));
  }

  final RegExp blockStart;

  final RegExp blockEnd;

  final RegExp variableStart;

  final RegExp variableEnd;

  final RegExp commentStart;

  final RegExp commentEnd;

  final List<Rule> rules;

  Iterable<Token> tokenize(String source) sync* {
    final scanner = SpanScanner(source);
    final buffer = StringBuffer();
    var match = false;

    while (!scanner.isDone) {
      for (var rule in rules) {
        if (match = rule.matcher(scanner)) {
          if (buffer.isNotEmpty) {
            yield Token.data(scanner.line, '$buffer');
            buffer.clear();
          }

          yield rule.tokenFactory(scanner);
          break;
        }
      }

      if (!match) {
        buffer.writeCharCode(scanner.readChar());
      }
    }

    if (buffer.isNotEmpty) {
      yield Token.data(scanner.line, '$buffer');
      buffer.clear();
    }
  }
}

class Rule {
  factory Rule.scan(Pattern pattern, Token Function(SpanScanner) match) =>
      Rule(pattern, (scanner) => scanner.scan(pattern), match);

  const Rule(this.pattern, this.matcher, this.tokenFactory);

  final Pattern pattern;

  final bool Function(SpanScanner) matcher;

  final Token Function(SpanScanner) tokenFactory;

  @override
  String toString() {
    final ePattern = '$pattern'.replaceAll(RegExp('\n'), r'\n');
    return 'Rule($ePattern)';
  }
}
