import 'package:jinja/src/markup.dart';
import "package:test/test.dart" hide escape;

void main() {
  group('Escape', () {
    test('Empty', () {
      expect(escape(''), equals(''));
    });

    test('Ascii', () {
      expect(
          escape('abcd&><\'"efgh'), equals('abcd&amp;&gt;&lt;&#39;&#34;efgh'));
      expect(escape('&><\'"efgh'), equals('&amp;&gt;&lt;&#39;&#34;efgh'));
      expect(escape('abcd&><\'"'), equals('abcd&amp;&gt;&lt;&#39;&#34;'));
    });

    test('2 byte', () {
      expect(escape('こんにちは&><\'"こんばんは'),
          equals('こんにちは&amp;&gt;&lt;&#39;&#34;こんばんは'));
      expect(escape('&><\'"こんばんは'), equals('&amp;&gt;&lt;&#39;&#34;こんばんは'));
      expect(escape('こんにちは&><\'"'), equals('こんにちは&amp;&gt;&lt;&#39;&#34;'));
    });

    test('4 byte', () {
      expect(escape('\\U0001F363\\U0001F362&><\'"\\U0001F37A xyz'),
          equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz'));
      expect(escape('&><\'"\\U0001F37A xyz'),
          equals(r'&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz'));
      expect(escape('\\U0001F363\\U0001F362&><\'"'),
          equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;'));
    });
  });
}
