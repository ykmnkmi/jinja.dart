import 'package:jinja/src/utils.dart' show escape;
import 'package:test/test.dart' hide escape;

void main() {
  group('Escape', () {
    test('empty', () {
      expect(escape(''), equals(''));
    });

    test('ascii', () {
      expect(
        escape('''abcd&><'"efgh'''),
        equals('abcd&amp;&gt;&lt;&#39;&quot;efgh'),
      );
      expect(
        escape('''&><'"efgh'''),
        equals('&amp;&gt;&lt;&#39;&quot;efgh'),
      );
      expect(
        escape('''abcd&><'"'''),
        equals('abcd&amp;&gt;&lt;&#39;&quot;'),
      );
    });

    test('2 byte', () {
      expect(
        escape('''こんにちは&><'"こんばんは'''),
        equals('こんにちは&amp;&gt;&lt;&#39;&quot;こんばんは'),
      );
      expect(
        escape('''&><'"こんばんは'''),
        equals('&amp;&gt;&lt;&#39;&quot;こんばんは'),
      );
      expect(
        escape('''こんにちは&><'"'''),
        equals('こんにちは&amp;&gt;&lt;&#39;&quot;'),
      );
    });

    test('4 byte', () {
      expect(
        escape(r'''\U0001F363\U0001F362&><'"\U0001F37A xyz'''),
        equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&quot;\U0001F37A xyz'),
      );
      expect(
        escape(r'''&><'"\U0001F37A xyz'''),
        equals(r'&amp;&gt;&lt;&#39;&quot;\U0001F37A xyz'),
      );
      expect(
        escape(r'''\U0001F363\U0001F362&><'"'''),
        equals(r'\U0001F363\U0001F362&amp;&gt;&lt;&#39;&quot;'),
      );
    });
  });
}
