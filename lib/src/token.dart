part of 'lexer.dart';

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

  @override
  String toString() {
    if (value.isEmpty) {
      return '#$type:$line';
    }

    return '#$type:$line $value';
  }
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
      if (Token.common[type] != value) {
        // TODO: update error message
        throw TemplateSyntaxError('$this');
      }

      value = null;
    } else {
      type ??= this.type;
    }

    return value == null ? Token.simple(line, type) : Token(line, type, value);
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
    for (final expression in expressions) {
      if (!expression.contains(':')) {
        if (test(expression)) {
          return true;
        }

        continue;
      }

      final parts = expression.split(':');

      if (test(parts[0], parts[1])) {
        return true;
      }
    }

    return false;
  }

  @override
  String toString() {
    if (value.isEmpty) {
      return '$type:$line';
    }

    return '$type:$line:$length \'${value.replaceAll('\'', '\\\'').replaceAll('\n', r'\n')}\'';
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

String describeExpression(String expression) {
  if (expression.contains(':')) {
    final parts = expression.split(':');

    assert(parts.length == 2);

    if (parts.first == 'name') {
      return parts.last;
    }
  }

  return describeTokenType(expression);
}

String describeToken(Token token) {
  if (token.type == 'name') {
    return token.value;
  }

  return describeTokenType(token.type);
}

String describeTokenType(String type) {
  switch (type) {
    case 'add':
      return '+';
    case 'sub':
      return '-';
    case 'div':
      return '/';
    case 'floordiv':
      return '//';
    case 'mul':
      return '*';
    case 'mod':
      return '%';
    case 'pow':
      return '**';
    case 'tilde':
      return '~';
    case 'lbracket':
      return '[';
    case 'rbracket':
      return ']';
    case 'lparen':
      return '(';
    case 'rparen':
      return ')';
    case 'lbrace':
      return '{';
    case 'rbrace':
      return '}';
    case 'eq':
      return '==';
    case 'ne':
      return '!=';
    case 'gt':
      return '>';
    case 'gteq':
      return '>=';
    case 'lt':
      return '<';
    case 'lteq':
      return '<=';
    case 'assign':
      return '=';
    case 'dot':
      return '.';
    case 'colon':
      return ':';
    case 'pipe':
      return '|';
    case 'comma':
      return ',';
    case 'semicolon':
      return ';';
    case 'comment_start':
      return 'start of comment';
    case 'comment_end':
      return 'end of comment';
    case 'comment':
      return 'comment';
    case 'linecomment':
      return 'comment';
    case 'block_start':
      return 'start of statement block';
    case 'block_end':
      return 'end of statement block';
    case 'variable_start':
      return 'start of print statement';
    case 'variable_end':
      return 'end of print statement';
    case 'linestatement_start':
      return 'start of line statement';
    case 'linestatement_end':
      return 'end of line statement';
    case 'data':
      return 'template data / text';
    case 'eof':
      return 'end of template';
    default:
      return type;
  }
}
