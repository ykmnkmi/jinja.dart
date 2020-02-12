import 'package:jinja/src/environment.dart';
import 'package:string_scanner/string_scanner.dart';

enum TokenType {
  // base tokens
  error,
  newLine,
  space,
  data,
  commentStart,
  commentEnd,
  variableStart,
  variableEnd,
  blockStart,
  blockEnd,
}

class Token {
  factory Token.newLine(int line) => Token(line, TokenType.space, '\n');

  factory Token.space(int line, String value) =>
      Token(line, TokenType.space, value);

  factory Token.data(int line, String value) =>
      Token(line, TokenType.data, value);

  factory Token.error(int line, String value) =>
      Token(line, TokenType.error, value);

  const Token(this.line, this.type, [this.value]);

  final int line;

  final TokenType type;

  final String value;

  @override
  String toString() => '[$type${value == null ? ']' : '|$value]'}';
}

final RegExp spaceRe = RegExp('[ \t]+');
final RegExp newLineRe = RegExp('\n');

class Tokens extends Iterable<Token> {
  Tokens(this.iterable, this.name, this.fileName);

  final Iterable<Token> iterable;

  final String name;

  final String fileName;

  @override
  Iterator<Token> get iterator => TokenIterator(this);
}

class TokenIterator implements Iterator<Token> {
  TokenIterator(this.tokens);

  final Tokens tokens;

  @override
  Token get current => null;

  @override
  bool moveNext() => null;
}

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
            RegExp(RegExp.escape(environment.commentEnd), unicode: true) {
    final tagRules = <List<Object>>[
      // block
      <Object>[
        environment.blockStart,
        Rule.scan(
            blockStart, (scanner) => Token(scanner.line, TokenType.blockStart))
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
    ];

    tagRules.sort((a, b) => (a.first as String).compareTo(b.first as String));

    rules = <Rule>[
      Rule.scan(newLineRe, (scanner) => Token.newLine(scanner.line)),
      Rule.scan(spaceRe,
          (scanner) => Token.space(scanner.line, scanner.lastMatch.group(0))),
      ...tagRules.map<Rule>((tagRule) => tagRule.last as Rule),
    ];
  }

  final RegExp blockStart;
  final RegExp blockEnd;
  final RegExp variableStart;
  final RegExp variableEnd;
  final RegExp commentStart;
  final RegExp commentEnd;

  List<Rule> rules;

  Iterable<Token> tokenize(String source) sync* {
    final scanner = SpanScanner(source);
    final buffer = StringBuffer();

    var match = false;

    while (!scanner.isDone) {
      for (var rule in rules) {
        if (match = rule.matches(scanner)) {
          if (buffer.isNotEmpty) {
            yield Token.data(scanner.line, buffer.toString());
            buffer.clear();
          }

          yield rule.match(scanner);
          break;
        }
      }

      if (!match) {
        buffer.writeCharCode(scanner.readChar());
      }
    }

    if (buffer.isNotEmpty) {
      yield Token.data(scanner.line, buffer.toString());
      buffer.clear();
    }
  }
}

class Rule {
  factory Rule.scan(Pattern pattern, Token Function(SpanScanner) match) =>
      Rule((scanner) => scanner.scan(pattern), match);

  const Rule(this.matches, this.match);

  final bool Function(SpanScanner) matches;
  final Token Function(SpanScanner) match;
}
