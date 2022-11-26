import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/lexer.dart';

class TokenReader {
  TokenReader(Iterable<Token> tokens)
      : iterator = tokens.iterator,
        pushed = <Token>[] {
    current = Token.simple(0, 'initial');
    next();
  }

  final Iterator<Token> iterator;

  final List<Token> pushed;

  late Token current;

  Iterable<Token> get values {
    return TokenIterable(this);
  }

  void push(Token token) {
    pushed.add(token);
  }

  Token look() {
    var old = next();
    var result = current;
    push(result);
    current = old;
    return result;
  }

  void skip([int n = 1]) {
    for (var i = 0; i < n; i += 1) {
      next();
    }
  }

  Token? nextIf(String type, [String? value]) {
    if (current.test(type, value)) {
      return next();
    }

    return null;
  }

  bool skipIf(String type, [String? value]) {
    return nextIf(type, value) != null;
  }

  Token next() {
    var result = current;

    if (pushed.isNotEmpty) {
      current = pushed.removeAt(0);
    } else if (current.type != 'eof') {
      if (iterator.moveNext()) {
        current = iterator.current;
      } else {
        eof();
      }
    }

    return result;
  }

  void eof() {
    current = Token.simple(current.line + current.length, 'eof');
  }

  Token expect(String type, [String? value]) {
    if (!current.test(type, value)) {
      if (current.type == 'eof') {
        throw TemplateSyntaxError('Unexpected end of template, expected $type');
      }

      throw TemplateSyntaxError('Expected token $type, got $current');
    }

    return next();
  }
}

class TokenIterable extends Iterable<Token> {
  TokenIterable(this.reader);

  final TokenReader reader;

  @override
  Iterator<Token> get iterator {
    return TokenIterator(reader);
  }
}

class TokenIterator extends Iterator<Token> {
  TokenIterator(this.reader);

  final TokenReader reader;

  @override
  Token get current {
    return reader.next();
  }

  @override
  bool moveNext() {
    if (reader.current.test('eof')) {
      reader.eof();
      return false;
    }

    return true;
  }
}
