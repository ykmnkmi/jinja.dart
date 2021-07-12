import 'package:jinja/runtime.dart';
import 'package:test/test.dart' hide escape;

void main() {
  group('Escape', () {
    test('empty', () {
      expect(escape(''), equals(''));
    });

    test('ascii', () {
      expect(escape(r'''abcd&><'"efgh'''),
          equals('abcd&amp;&gt;&lt;&#39;&#34;efgh'));
      expect(escape(r'''&><'"efgh'''), equals('&amp;&gt;&lt;&#39;&#34;efgh'));
      expect(escape(r'''abcd&><'"'''), equals('abcd&amp;&gt;&lt;&#39;&#34;'));
    });

    test('2 byte', () {
      expect(escape(r'''こんにちは&><'"こんばんは'''),
          equals('こんにちは&amp;&gt;&lt;&#39;&#34;こんばんは'));
      expect(escape(r'''&><'"こんばんは'''), equals('&amp;&gt;&lt;&#39;&#34;こんばんは'));
      expect(escape(r'''こんにちは&><'"'''), equals('こんにちは&amp;&gt;&lt;&#39;&#34;'));
    });

    test('4 byte', () {
      expect(escape(r'''\U0001F363\U0001F362&><'"\U0001F37A xyz'''),
          equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz'));
      expect(escape(r'''&><'"\U0001F37A xyz'''),
          equals(r'&amp;&gt;&lt;&#39;&#34;\U0001F37A xyz'));
      expect(escape(r'''\U0001F363\U0001F362&><'"'''),
          equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&#34;'));
    });
  });
}
