import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('tests', () {
    var env = Environment();

    test('no paren for arg 1', () {
      var template = env.fromString('{{ foo is sameas none }}');
      expect(template.renderWr(foo: null), equals('true'));
    });

    test('defined', () {
      var template = env.fromString('{{ missing is defined }}|'
          '{{ true is defined }}');
      expect(template.render(), equals('false|true'));
    });

    test('even', () {
      var template = env.fromString('{{ 1 is even }}|{{ 2 is even }}');
      expect(template.render(), equals('false|true'));
    });

    test('odd', () {
      var template = env.fromString('{{ 1 is odd }}|{{ 2 is odd }}');
      expect(template.render(), equals('true|false'));
    });

    test('lower', () {
      var template = env.fromString('{{ "foo" is lower }}|{{ "FOO" is lower }}');
      expect(template.render(), equals('true|false'));
    });

    test('type checks', () {
      var template = env.fromString('{{ 42 is undefined }}|'
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
          template.renderWr(mydict: <Object, Object>{}),
          equals('false|true|false|true|true|false|true|true|true|true|false|'
              'true|true|true|false|true|true|true'));
    });

    test('sequence', () {
      var template = env.fromString('{{ [1, 2, 3] is sequence }}|'
          '{{ "foo" is sequence }}|'
          '{{ 42 is sequence }}');
      expect(template.render(), equals('true|true|false'));
    });

    test('upper', () {
      var template = env.fromString('{{ "FOO" is upper }}|{{ "foo" is upper }}');
      expect(template.render(), equals('true|false'));
    });

    test('equal to', () {
      var template = env.fromString('{{ foo is eq 12 }}|'
          '{{ foo is eq 0 }}|'
          '{{ foo is eq (3 * 4) }}|'
          '{{ bar is eq "baz" }}|'
          '{{ bar is eq "zab" }}|'
          '{{ bar is eq ("ba" + "z") }}|'
          '{{ bar is eq bar }}|'
          '{{ bar is eq foo }}');
      expect(template.renderWr(foo: 12, bar: 'baz'), equals('true|false|true|true|false|true|true|false'));
    });

    test('compare aliases', () {
      var template = env.fromString('{{ 2 is eq 2 }}|{{ 2 is eq 3 }}|'
          '{{ 2 is ne 3 }}|{{ 2 is ne 2 }}|{{ 2 is lt 3 }}|'
          '{{ 2 is lt 2 }}|{{ 2 is le 2 }}|{{ 2 is le 1 }}|'
          '{{ 2 is gt 1 }}|{{ 2 is gt 2 }}|{{ 2 is ge 2 }}|'
          '{{ 2 is ge 3 }}');
      expect(
          template.renderWr(foo: 12, bar: 'baz'),
          equals('true|false|true|false|true|false|true|false|true|false|'
              'true|false'));
    });

    test('same as', () {
      var template = env.fromString('{{ foo is sameas false }}|'
          '{{ 0 is sameas false }}');
      expect(template.renderWr(foo: false), equals('true|false'));
    });

    test('greater than', () {
      var template = env.fromString('{{ 1 is greaterthan 0 }}|'
          '{{ 0 is greaterthan 1 }}');
      expect(template.render(), equals('true|false'));
    });

    test('less than', () {
      var template = env.fromString('{{ 0 is lessthan 1 }}|'
          '{{ 1 is lessthan 0 }}');
      expect(template.render(), equals('true|false'));
    });

    test('multiple test', () {
      var items = <List<String>>[];

      bool matching(String x, String y) {
        items.add(<String>[x, y]);
        return false;
      }

      var env = Environment(tests: <String, Function>{'matching': matching});
      var template = env.fromString('{{ "us-west-1" is matching '
          '"(us-east-1|ap-northeast-1)" '
          'or "stage" is matching "(dev|stage)" }}');

      expect(template.render(), equals('false'));
      expect(
          items,
          equals(<List<Object>>[
            <String>['us-west-1', '(us-east-1|ap-northeast-1)'],
            <String>['stage', '(dev|stage)']
          ]));
    });

    test('in', () {
      var template = env.fromString('{{ "o" is in "foo" }}|'
          '{{ "foo" is in "foo" }}|'
          '{{ "b" is in "foo" }}|'
          '{{ 1 is in ((1, 2)) }}|'
          '{{ 3 is in ((1, 2)) }}|'
          '{{ 1 is in [1, 2] }}|'
          '{{ 3 is in [1, 2] }}|'
          '{{ "foo" is in {"foo": 1}}}|'
          '{{ "baz" is in {"bar": 1}}}');
      expect(template.render(), equals('true|true|false|true|false|true|false|true|false'));
    });
  });
}
