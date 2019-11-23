import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('tests', () {
    Environment env = Environment();

    test('no paren for arg 1', () {
      Template template = env.fromString('{{ foo is sameas none }}');
      expect(template.renderMap(<String, Object>{'foo': null}), equals('true'));
    });

    test('defined', () {
      Template template = env.fromString('{{ missing is defined }}|'
          '{{ true is defined }}');
      expect(template.renderMap(), equals('false|true'));
    });

    test('even', () {
      Template template = env.fromString('{{ 1 is even }}|{{ 2 is even }}');
      expect(template.renderMap(), equals('false|true'));
    });

    test('odd', () {
      Template template = env.fromString('{{ 1 is odd }}|{{ 2 is odd }}');
      expect(template.renderMap(), equals('true|false'));
    });

    test('lower', () {
      Template template = env.fromString('{{ "foo" is lower }}|{{ "FOO" is lower }}');
      expect(template.renderMap(), equals('true|false'));
    });

    test('type checks', () {
      Template template = env.fromString('{{ 42 is undefined }}|'
          '{{ 42 is defined }}|'
          '{{ 42 is none }}|'
          '{{ none is none }}|'
          '{{ 42 is number }}|'
          '{{ 42 is string }}|'
          '{{ "foo" is string }}|'
          '{{ "foo" is sequence }}|'
          '{{ [1] is sequence }}|'
          '{{ range is callable }}|'
          '{{ 42 is callable }}|'
          '{{ range(5) is iterable }}|'
          '{{ {} is mapping }}|'
          '{{ mydict is mapping }}|'
          '{{ [] is mapping }}|'
          '{{ 10 is number }}|'
          '{{ (10 ** 2) is number }}|'
          '{{ 3.14159 is number }}');
      expect(
          template.renderMap(<String, Object>{'mydict': <Object, Object>{}}),
          equals('false|true|false|true|true|false|true|true|true|true|false|'
              'true|true|true|false|true|true|true'));
    });

    test('sequence', () {
      Template template = env.fromString('{{ [1, 2, 3] is sequence }}|'
          '{{ "foo" is sequence }}|'
          '{{ 42 is sequence }}');
      expect(template.renderMap(), equals('true|true|false'));
    });

    test('upper', () {
      Template template = env.fromString('{{ "FOO" is upper }}|{{ "foo" is upper }}');
      expect(template.renderMap(), equals('true|false'));
    });

    test('equal to', () {
      Template template = env.fromString('{{ foo is eq 12 }}|'
          '{{ foo is eq 0 }}|'
          '{{ foo is eq (3 * 4) }}|'
          '{{ bar is eq "baz" }}|'
          '{{ bar is eq "zab" }}|'
          '{{ bar is eq ("ba" + "z") }}|'
          '{{ bar is eq bar }}|'
          '{{ bar is eq foo }}');
      expect(template.renderMap(<String, Object>{'foo': 12, 'bar': 'baz'}),
          equals('true|false|true|true|false|true|true|false'));
    });

    test('compare aliases', () {
      Template template = env.fromString('{{ 2 is eq 2 }}|{{ 2 is eq 3 }}|'
          '{{ 2 is ne 3 }}|{{ 2 is ne 2 }}|{{ 2 is lt 3 }}|'
          '{{ 2 is lt 2 }}|{{ 2 is le 2 }}|{{ 2 is le 1 }}|'
          '{{ 2 is gt 1 }}|{{ 2 is gt 2 }}|{{ 2 is ge 2 }}|'
          '{{ 2 is ge 3 }}');
      expect(
          template.renderMap(<String, Object>{'foo': 12, 'bar': 'baz'}),
          equals('true|false|true|false|true|false|true|false|true|false|'
              'true|false'));
    });

    test('same as', () {
      Template template = env.fromString('{{ foo is sameas false }}|'
          '{{ 0 is sameas false }}');
      expect(template.renderMap(<String, Object>{'foo': false}), equals('true|false'));
    });

    test('greater than', () {
      Template template = env.fromString('{{ 1 is greaterthan 0 }}|'
          '{{ 0 is greaterthan 1 }}');
      expect(template.renderMap(), equals('true|false'));
    });

    test('less than', () {
      Template template = env.fromString('{{ 0 is lessthan 1 }}|'
          '{{ 1 is lessthan 0 }}');
      expect(template.renderMap(), equals('true|false'));
    });

    test('multiple test', () {
      List<List<String>> items = <List<String>>[];
      bool matching(String x, String y) {
        items.add(<String>[x, y]);
        return false;
      }

      Environment env = Environment(tests: <String, Function>{'matching': matching});
      Template template = env.fromString('{{ "us-west-1" is matching '
          '"(us-east-1|ap-northeast-1)" '
          'or "stage" is matching "(dev|stage)" }}');

      expect(template.renderMap(), equals('false'));
      expect(
          items,
          equals(<List<Object>>[
            <String>['us-west-1', '(us-east-1|ap-northeast-1)'],
            <String>['stage', '(dev|stage)']
          ]));
    });

    test('in', () {
      Template template = env.fromString('{{ "o" is in "foo" }}|'
          '{{ "foo" is in "foo" }}|'
          '{{ "b" is in "foo" }}|'
          '{{ 1 is in ((1, 2)) }}|'
          '{{ 3 is in ((1, 2)) }}|'
          '{{ 1 is in [1, 2] }}|'
          '{{ 3 is in [1, 2] }}|'
          '{{ "foo" is in {"foo": 1}}}|'
          '{{ "baz" is in {"bar": 1}}}');
      expect(template.renderMap(), equals('true|true|false|true|false|true|false|true|false'));
    });
  });
}
