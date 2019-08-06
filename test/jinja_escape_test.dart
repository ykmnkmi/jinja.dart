import 'package:jinja/src/markup.dart';
import "package:test/test.dart" hide escape;

// From https://github.com/pallets/markupsafe/blob/master/tests/test_escape.py

void main() {
  group('Escape', () {
    test('Empty', () {
      expect(escape(''), equals(Markup('')));
    });

    test('Ascii', () {
      expect(escape('abcd&><\'"efgh'),
          equals(Markup('abcd&amp;&gt;&lt;&#39;&#34;efgh')));
      expect(
          escape('&><\'"efgh'), equals(Markup('&amp;&gt;&lt;&#39;&#34;efgh')));
      expect(
          escape('abcd&><\'"'), equals(Markup('abcd&amp;&gt;&lt;&#39;&#34;')));
    });

    test('2 byte', () {
      expect(escape('こんにちは&><\'"こんばんは'),
          equals(Markup('こんにちは&amp;&gt;&lt;&#39;&#34;こんばんは')));
      expect(escape('&><\'"こんばんは'),
          equals(Markup('&amp;&gt;&lt;&#39;&#34;こんばんは')));
      expect(escape('こんにちは&><\'"'),
          equals(Markup('こんにちは&amp;&gt;&lt;&#39;&#34;')));
    });

    test('4 byte', () {
      expect(
          escape('\\U0001F363\\U0001F362&><\'"\\U0001F37A xyz'),
          equals(Markup(
              r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz')));
      expect(escape('&><\'"\\U0001F37A xyz'),
          equals(Markup(r'&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz')));
      expect(escape('\\U0001F363\\U0001F362&><\'"'),
          equals(Markup(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;')));
    });
  });
}
