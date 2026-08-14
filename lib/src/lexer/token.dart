part of '/src/lexer.dart';

/// Bind operators to token types.
const Map<String, String> _operators = <String, String>{
  '-': TokenType.sub,
  ',': TokenType.comma,
  ';': TokenType.semicolon,
  ':': TokenType.colon,
  '!=': TokenType.ne,
  '.': TokenType.dot,
  '(': TokenType.lParen,
  ')': TokenType.rParen,
  '[': TokenType.lBracket,
  ']': TokenType.rBracket,
  '{': TokenType.lBrace,
  '}': TokenType.rBrace,
  '*': TokenType.mul,
  '**': TokenType.pow,
  '/': TokenType.div,
  '//': TokenType.floorDiv,
  '%': TokenType.mod,
  '+': TokenType.add,
  '<': TokenType.lt,
  '<=': TokenType.ltEq,
  '=': TokenType.assign,
  '==': TokenType.eq,
  '>': TokenType.gt,
  '>=': TokenType.gtEq,
  '|': TokenType.pipe,
  '~': TokenType.tilde,
  '??': TokenType.nullCoalesce,
  '?': TokenType.question,
};

final Map<String, String> _reverseOperators = _operators.map<String, String>(
  (key, value) => MapEntry<String, String>(value, key),
);

final RegExp _operatorRe = RegExp(
  '(${(_operators.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).map<String>(RegExp.escape).join('|')})',
);

const Map<String, String> _simpleTokens = <String, String>{
  TokenType.add: '+',
  TokenType.assign: '=',
  TokenType.colon: ':',
  TokenType.comma: ',',
  TokenType.div: '/',
  TokenType.dot: '.',
  TokenType.eq: '==',
  TokenType.eof: '',
  TokenType.floorDiv: '//',
  TokenType.gt: '>',
  TokenType.gtEq: '>=',
  TokenType.initial: '',
  TokenType.lBrace: '{',
  TokenType.lBracket: '[',
  TokenType.lParen: '(',
  TokenType.lt: '<',
  TokenType.ltEq: '<=',
  TokenType.mod: '%',
  TokenType.mul: '*',
  TokenType.ne: '!=',
  TokenType.pipe: '|',
  TokenType.pow: '**',
  TokenType.rBrace: '}',
  TokenType.rBracket: ']',
  TokenType.rParen: ')',
  TokenType.semicolon: ';',
  TokenType.sub: '-',
  TokenType.tilde: '~',
};

const List<String> _ignoredTokens = <String>[
  TokenType.whitespace,
  TokenType.commentBegin,
  TokenType.comment,
  TokenType.commentEnd,
  TokenType.rawBegin,
  TokenType.rawEnd,
  TokenType.lineCommentBegin,
  TokenType.lineCommentEnd,
  TokenType.lineComment,
];

const List<String> _ignoreIfEmpty = <String>[
  TokenType.whitespace,
  TokenType.data,
  TokenType.comment,
  TokenType.lineComment,
];

String _describeTokenType(String type) {
  const tokenDescriptions = <String, String>{
    TokenType.commentBegin: 'start of comment',
    TokenType.commentEnd: 'end of comment',
    TokenType.comment: 'comment',
    TokenType.lineComment: 'comment',
    TokenType.blockBegin: 'start of statement block',
    TokenType.blockEnd: 'end of statement block',
    TokenType.variableBegin: 'start of print statement',
    TokenType.variableEnd: 'end of print statement',
    TokenType.lineStatementBegin: 'start of line statement',
    TokenType.lineStatementEnd: 'end of line statement',
    TokenType.data: 'template data / text',
    TokenType.eof: 'end of template',
  };

  return _reverseOperators[type] ?? tokenDescriptions[type] ?? type;
}

/// Returns a description of te token.
String describeToken(Token token) {
  if (token.type == TokenType.name) {
    return token.value;
  }

  return _describeTokenType(token.type);
}

/// Like [describeToken] but for token records.
String describeTokenRecord((String, String?) expression) {
  var (type, value) = expression;

  if (type == TokenType.name && value != null) {
    return value;
  }

  return _describeTokenType(type);
}

abstract final class Token {
  const factory(int line, String type, String value) = _ValueToken;

  const factory simple(int line, String type) = _SimpleToken;

  int get line;

  int get length;

  String get type;

  String get value;

  Token change({int line, String type, String value});

  /// Test a token against a token [type] and [value].
  bool match(String type, String? value);

  /// Test against multiple token records.
  bool matchAny(Iterable<(String, String?)> expressions);
}

abstract base class _BaseToken implements Token {
  const new();

  @override
  int get hashCode {
    return type.hashCode & line & value.hashCode;
  }

  @override
  int get length {
    return value.length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Token &&
        type == other.type &&
        line == other.line &&
        value == other.value;
  }

  @override
  Token change({int? line, String? type, String? value}) {
    line ??= this.line;
    value ??= this.value;

    if (type != null && _simpleTokens.containsKey(type)) {
      return Token.simple(line, type);
    }

    return Token(line, type ?? this.type, value);
  }

  @override
  bool match(String type, String? value) {
    return type == this.type && (value == null || value == this.value);
  }

  @override
  bool matchAny(Iterable<(String, String?)> expressions) {
    for (var (type, value) in expressions) {
      if (match(type, value)) {
        return true;
      }
    }

    return false;
  }
}

final class _SimpleToken extends _BaseToken {
  const new(this.line, this.type);

  @override
  final int line;

  @override
  final String type;

  @override
  String get value {
    return _simpleTokens[type]!;
  }
}

final class _ValueToken extends _BaseToken {
  const new(this.line, this.type, this.value);

  @override
  final int line;

  @override
  final String type;

  @override
  final String value;
}
