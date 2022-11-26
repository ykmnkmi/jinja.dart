part of 'lexer.dart';

const Map<String, String> tokenDescriptions = <String, String>{
  'add': '+',
  'sub': '-',
  'div': '/',
  'floordiv': '//',
  'mul': '*',
  'mod': '%',
  'pow': '**',
  'tilde': '~',
  'lbracket': '[',
  'rbracket': ']',
  'lparen': '(',
  'rparen': ')',
  'lbrace': '{',
  'rbrace': '}',
  'eq': '==',
  'ne': '!=',
  'gt': '>',
  'gteq': '>=',
  'lt': '<',
  'lteq': '<=',
  'assign': '=',
  'dot': '.',
  'colon': ':',
  'pipe': '|',
  'comma': ',',
  'semicolon': ';',
  'comment_start': 'start of comment',
  'comment_end': 'end of comment',
  'comment': 'comment',
  'linecomment': 'comment',
  'block_start': 'start of statement block',
  'block_end': 'end of statement block',
  'variable_start': 'start of print statement',
  'variable_end': 'end of print statement',
  'linestatement_start': 'start of line statement',
  'linestatement_end': 'end of line statement',
  'data': 'template data / text',
  'eof': 'end of template',
};

String describeTokenType(String type) {
  return tokenDescriptions[type] ?? type;
}

String describeToken(Token token) {
  if (token.type == 'name') {
    return token.value;
  }

  return describeTokenType(token.type);
}

String describeExpression(String expression) {
  if (expression.contains(':')) {
    var parts = expression.split(':');
    assert(parts.length == 2);

    if (parts.first == 'name') {
      return parts.last;
    }
  }

  return describeTokenType(expression);
}

abstract class Token {
  static const Map<String, String> common = <String, String>{
    'add': '+',
    'assign': '=',
    'colon': ':',
    'comma': ',',
    'div': '/',
    'dot': '.',
    'eq': '==',
    'eof': '',
    'floordiv': '//',
    'gt': '>',
    'gteq': '>=',
    'initial': '',
    'lbrace': '{',
    'lbracket': '[',
    'lparen': '(',
    'lt': '<',
    'lteq': '<=',
    'mod': '%',
    'mul': '*',
    'ne': '!=',
    'pipe': '|',
    'pow': '**',
    'rbrace': '}',
    'rbracket': ']',
    'rparen': ')',
    'semicolon': ';',
    'sub': '-',
    'tilde': '~',
  };

  const factory Token(int line, String type, String value) = ValueToken;

  const factory Token.simple(int line, String type) = SimpleToken;

  @override
  int get hashCode {
    return type.hashCode & line & value.hashCode;
  }

  int get line;

  int get length;

  String get type;

  String get value;

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

  Token change({int line, String type, String value});

  bool test(String type, [String? value]);

  bool testAny(Iterable<String> expressions);
}

abstract class BaseToken implements Token {
  const BaseToken();

  @override
  int get length {
    return value.length;
  }

  @override
  Token change({int? line, String? type, String? value}) {
    line ??= this.line;
    value ??= this.value;

    if (type != null && Token.common.containsKey(type)) {
      return Token.simple(line, type);
    }

    return Token(line, type ?? this.type, value);
  }

  @override
  bool test(String type, [String? value]) {
    if (value == null) {
      return type == this.type;
    }

    return type == this.type && value == this.value;
  }

  @override
  bool testAny(Iterable<String> expressions) {
    for (var expression in expressions) {
      if (!expression.contains(':')) {
        if (test(expression)) {
          return true;
        }

        continue;
      }

      var parts = expression.split(':');

      if (test(parts[0], parts[1])) {
        return true;
      }
    }

    return false;
  }
}

class SimpleToken extends BaseToken {
  const SimpleToken(this.line, this.type);

  @override
  final int line;

  @override
  final String type;

  @override
  String get value {
    return Token.common[type] ?? '';
  }
}

class ValueToken extends BaseToken {
  const ValueToken(this.line, this.type, this.value);

  @override
  final int line;

  @override
  final String type;

  @override
  final String value;
}
