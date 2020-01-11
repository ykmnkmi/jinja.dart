import 'package:jinja/src/environment.dart';
import 'package:string_scanner/string_scanner.dart';

enum TokenType {
  // base tokens
  blockEnd,
  blockStart,
  variableEnd,
  variableStart,
  commentEnd,
  commentStart,
  data,
  space,
  newLine,
  error,
}

class Token {
  static const Token newLine = Token(TokenType.newLine);

  factory Token.data(String value) => Token(TokenType.data, value);
  factory Token.space(String value) => Token(TokenType.space, value);
  factory Token.error(String value) => Token(TokenType.error, value);

  const Token(this.type, [this.value]);

  final TokenType type;
  final String value;

  @override
  String toString() => '[$type${value == null ? ']' : '|$value]'}';
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
            RegExp(RegExp.escape(environment.commentEnd), unicode: true) {
    final List<List<Object>> tagRules = <List<Object>>[
      // block
      <Object>[
        environment.blockStart,
        Rule.scan(
            blockStart, (StringScanner scanner) => Token(TokenType.blockStart))
      ],
      <Object>[
        environment.blockEnd,
        Rule.scan(
            blockEnd, (StringScanner scanner) => Token(TokenType.blockEnd))
      ],
      // variable
      <Object>[
        environment.variableStart,
        Rule.scan(variableStart,
            (StringScanner scanner) => Token(TokenType.variableStart))
      ],
      <Object>[
        environment.variableEnd,
        Rule.scan(variableEnd,
            (StringScanner scanner) => Token(TokenType.variableEnd))
      ],
      // comment
      <Object>[
        environment.commentStart,
        Rule.scan(commentStart,
            (StringScanner scanner) => Token(TokenType.commentStart))
      ],
      <Object>[
        environment.commentEnd,
        Rule.scan(
            commentEnd, (StringScanner scanner) => Token(TokenType.commentEnd))
      ],
    ];

    tagRules.sort((List<Object> a, List<Object> b) =>
        (a.first as String).compareTo(b.first as String));

    rules = <Rule>[
      Rule.scan(newLineRe, (StringScanner scanner) => Token.newLine),
      Rule.scan(spaceRe,
          (StringScanner scanner) => Token.space(scanner.lastMatch.group(0))),
      ...tagRules.map<Rule>((List<Object> tagRule) => tagRule.last as Rule),
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
    final StringScanner scanner = StringScanner(source);
    final StringBuffer buffer = StringBuffer();

    bool match = false;

    while (!scanner.isDone) {
      for (Rule rule in rules) {
        if (match = rule.matches(scanner)) {
          if (buffer.isNotEmpty) {
            yield Token.data(buffer.toString());
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
  }
}

class Rule {
  factory Rule.scan(Pattern pattern, Token Function(StringScanner) match) =>
      Rule((StringScanner scanner) => scanner.scan(pattern), match);

  const Rule(this.matches, this.match);

  final bool Function(StringScanner scanner) matches;
  final Token Function(StringScanner scanner) match;
}
