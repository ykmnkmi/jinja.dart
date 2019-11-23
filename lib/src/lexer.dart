import 'dart:async';

import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:source_span/source_span.dart';

import 'package:quiver/core.dart' as quiver;

import 'environment.dart';

enum TokenType {
  add,
  sub,
  div,
  floorDiv,
  mul,
  mod,
  pow,
  tilde,
  lbrace,
  rbrace,
  lbracket,
  rbracket,
  lparen,
  rparen,
  eq,
  ne,
  gt,
  gteq,
  lt,
  lteq,
  assign,
  dot,
  colon,
  pipe,
  comma,
  semicolon,

  initial,
  whitespace,
  operator,
  integer,
  float,
  string,
  name,
  rawBegin,
  rawEnd,

  commentBegin,
  commentEnd,
  comment,
  lineCommentBegin,
  lineCommentEnd,
  lineComment,
  blockBegin,
  blockEnd,
  variableBegin,
  variableEnd,
  lineStatementBegin,
  lineStatementEnd,
  data,
  eof,
}

class Token {
  static String describe(Token token) {
    switch (token.type) {
      case TokenType.add:
      case TokenType.sub:
      case TokenType.div:
      case TokenType.floorDiv:
      case TokenType.mul:
      case TokenType.mod:
      case TokenType.pow:
      case TokenType.tilde:
      case TokenType.lbrace:
      case TokenType.rbrace:
      case TokenType.lbracket:
      case TokenType.rbracket:
      case TokenType.lparen:
      case TokenType.rparen:
      case TokenType.eq:
      case TokenType.ne:
      case TokenType.gt:
      case TokenType.gteq:
      case TokenType.lt:
      case TokenType.lteq:
      case TokenType.assign:
      case TokenType.dot:
      case TokenType.colon:
      case TokenType.pipe:
      case TokenType.comma:
      case TokenType.semicolon:
      case TokenType.name:
        return token.value;
      case TokenType.commentBegin:
        return 'begin of comment';
      case TokenType.commentEnd:
        return 'end of comment';
      case TokenType.comment:
        return 'comment';
      case TokenType.lineComment:
        return 'comment';
      case TokenType.blockBegin:
        return 'begin of statement block';
      case TokenType.blockEnd:
        return 'end of statement block';
      case TokenType.variableBegin:
        return 'begin of print statement';
      case TokenType.variableEnd:
        return 'end of print statement';
      case TokenType.lineStatementBegin:
        return 'begin of line statement';
      case TokenType.lineStatementEnd:
        return 'end of line statement';
      case TokenType.data:
        return 'template data / text';
      case TokenType.eof:
        return 'end of template';
      default:
        return token.type.toString();
    }
  }

  static const Token initial = Token(TokenType.initial, '');
  static const Token whitespace = Token(TokenType.whitespace, ' ');
  static const Token eof = Token(TokenType.eof, '');

  static const Token add = Token(TokenType.add, '+');
  static const Token sub = Token(TokenType.sub, '-');
  static const Token div = Token(TokenType.div, '/');
  static const Token floorDiv = Token(TokenType.floorDiv, '//');
  static const Token mul = Token(TokenType.mul, '*');
  static const Token mod = Token(TokenType.mod, '%');
  static const Token pow = Token(TokenType.pow, '**');
  static const Token tilde = Token(TokenType.tilde, '~');
  static const Token lbracket = Token(TokenType.lbracket, '[');
  static const Token rbracket = Token(TokenType.rbracket, ']');
  static const Token lparen = Token(TokenType.lparen, '(');
  static const Token rparen = Token(TokenType.rparen, ')');
  static const Token lbrace = Token(TokenType.lbrace, '{');
  static const Token rbrace = Token(TokenType.rbrace, '}');
  static const Token eq = Token(TokenType.eq, '==');
  static const Token ne = Token(TokenType.ne, '!=');
  static const Token gt = Token(TokenType.gt, '>');
  static const Token gteq = Token(TokenType.gteq, '>=');
  static const Token lt = Token(TokenType.lt, '<');
  static const Token lteq = Token(TokenType.lteq, '<=');
  static const Token assign = Token(TokenType.assign, '=');
  static const Token dot = Token(TokenType.dot, '.');
  static const Token colon = Token(TokenType.colon, ':');
  static const Token pipe = Token(TokenType.pipe, '|');
  static const Token comma = Token(TokenType.comma, ',');
  static const Token semicolon = Token(TokenType.semicolon, ';');

  const Token(this.type, this.value);

  final TokenType type;
  final String value;

  @override
  int get hashCode => quiver.hash2(value, type);

  @override
  bool operator ==(Object other) => other is Token && type == other.type && value == other.value;

  @override
  String toString() => Token.describe(this);
}

class Lexer {
  Lexer(Environment environment);

  Iterable<Token> tokeniter(String source, {String name, String fileName}) sync* {}
}
