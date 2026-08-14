part of '/src/lexer.dart';

/// A token reader.
///
/// The current active token is stored as [current].
final class TokenReader {
  new(Iterable<Token> tokens, {this.name, this.path})
    : _iterator = tokens.iterator,
      _pushed = <Token>[] {
    current = const Token.simple(0, TokenType.initial);
    next();
  }

  final String? name;

  final String? path;

  final Iterator<Token> _iterator;

  final List<Token> _pushed;

  late Token current;

  /// Are we at the end of the stream?
  bool get isEof {
    return _pushed.isEmpty && current.type == TokenType.eof;
  }

  /// Push a token back to the stream.
  void push(Token token) {
    _pushed.add(token);
  }

  /// Look at the next token.
  Token look() {
    var old = next();
    var result = current;
    push(result);
    current = old;
    return result;
  }

  /// Got n tokens ahead.
  void skip([int n = 1]) {
    for (var i = 0; i < n; i += 1) {
      next();
    }
  }

  /// Perform the token test and return the token if it matched.
  ///
  /// This accepts the same argument as [Token.match].
  Token? nextIf(String type, [String? value]) {
    if (current.match(type, value)) {
      return next();
    }

    return null;
  }

  /// Like [nextIf] but only returns `true` or `false`.
  ///
  /// This accepts the same argument as [Token.match].
  bool skipIf(String type, [String? value]) {
    return nextIf(type, value) != null;
  }

  /// Go one token ahead and return the old one.
  Token next() {
    var result = current;

    if (_pushed.isNotEmpty) {
      current = _pushed.removeAt(0);
    } else if (current.type != TokenType.eof) {
      if (_iterator.moveNext()) {
        current = _iterator.current;
      } else {
        current = Token.simple(current.line, TokenType.eof);
      }
    }

    return result;
  }

  /// Expect a given token type and return it.
  ///
  /// This accepts the same argument as [Token.match].
  Token expect(String type, [String? value]) {
    if (!current.match(type, value)) {
      if (current.type == TokenType.eof) {
        throw TemplateSyntaxError(
          'Unexpected end of template, '
          'expected ${describeTokenRecord((type, value))}',
        );
      }

      throw TemplateSyntaxError('Expected token $type, got ${current.value}');
    }

    return next();
  }
}
