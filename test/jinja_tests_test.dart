import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

// From https://github.com/pallets/markupsafe/blob/master/tests/test_tests.py

void main() {
  group('Tests', () {
    var env = Environment();

    test('Defined', () {
      final template = env.fromSource('{{ missing is defined }}|'
          '{{ true is defined }}');
      expect(template.render(), equals('false|true'));
    });

    test('Even', () {
      final template = env.fromSource('{{ 1 is even }}|{{ 2 is even }}');
      expect(template.render(), equals('false|true'));
    });

    test('Odd', () {
      final template = env.fromSource('{{ 1 is odd }}|{{ 2 is odd }}');
      expect(template.render(), equals('true|false'));
    });

    test('Lower', () {
      final template =
          env.fromSource('{{ "foo" is lower }}|{{ "FOO" is lower }}');
      expect(template.render(), equals('true|false'));
    });

    test('Type Checks', () {
      final template = env.fromSource('{{ 42 is undefined }}|'
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
          '{{ (10 ** 100) is number }}|'
          '{{ 3.14159 is number }}');
      expect(
          template.render({'mydict': {}}),
          equals('false|true|false|true|true|false|true|true|true|true|false|'
              'true|true|true|false|true|true|true'));
    });

    test('Sequence', () {
      final template = env.fromSource('{{ [1, 2, 3] is sequence }}|'
          '{{ "foo" is sequence }}|'
          '{{ 42 is sequence }}');
      expect(template.render(), equals('true|true|false'));
    });

    test('Upper', () {
      final template =
          env.fromSource('{{ "FOO" is upper }}|{{ "foo" is upper }}');
      expect(template.render(), equals('true|false'));
    });

    test('Equal To', () {
      final template = env.fromSource('{{ foo is eq 12 }}|'
          '{{ foo is eq 0 }}|'
          '{{ foo is eq (3 * 4) }}|'
          '{{ bar is eq "baz" }}|'
          '{{ bar is eq "zab" }}|'
          '{{ bar is eq ("ba" + "z") }}|'
          '{{ bar is eq bar }}|'
          '{{ bar is eq foo }}');
      expect(template.render({'foo': 12, 'bar': 'baz'}),
          equals('true|false|true|true|false|true|true|false'));
    });

    test('Compare Aliases', () {
      final template = env.fromSource('{{ 2 is eq 2 }}|{{ 2 is eq 3 }}|'
          '{{ 2 is ne 3 }}|{{ 2 is ne 2 }}|{{ 2 is lt 3 }}|'
          '{{ 2 is lt 2 }}|{{ 2 is le 2 }}|{{ 2 is le 1 }}|'
          '{{ 2 is gt 1 }}|{{ 2 is gt 2 }}|{{ 2 is ge 2 }}|'
          '{{ 2 is ge 3 }}');
      expect(
          template.render({'foo': 12, 'bar': 'baz'}),
          equals('true|false|true|false|true|false|true|false|true|false|'
              'true|false'));
    });

    test('Same As', () {
      final template = env.fromSource('{{ foo is sameas false }}|'
          '{{ 0 is sameas false }}');
      expect(template.render({'foo': false}), equals('true|false'));
    });

    test('No Paren For Arg 1', () {
      final template = env.fromSource('{{ foo is sameas none }}');
      expect(template.render({'foo': null}), equals('true'));
    });

    test('Greater Than', () {
      final template = env.fromSource('{{ 1 is greaterthan 0 }}|'
          '{{ 0 is greaterthan 1 }}');
      expect(template.render(), equals('true|false'));
    });

    test('Less Than', () {
      final template = env.fromSource('{{ 0 is lessthan 1 }}|'
          '{{ 1 is lessthan 0 }}');
      expect(template.render(), equals('true|false'));
    });

    test('Multiple Test', () {
      final items = [];
      bool matching(x, y) {
        items.add([x, y]);
        return false;
      }

      env = Environment(tests: {'matching': matching});
      final template = env.fromSource('{{ "us-west-1" is matching '
          '"(us-east-1|ap-northeast-1)" '
          'or "stage" is matching "(dev|stage)" }}');

      expect(template.render(), equals('false'));
      expect(
          items,
          equals([
            ['us-west-1', '(us-east-1|ap-northeast-1)'],
            ['stage', '(dev|stage)']
          ]));
    });

    test('In', () {
      final template = env.fromSource('{{ "o" is in "foo" }}|'
          '{{ "foo" is in "foo" }}|'
          '{{ "b" is in "foo" }}|'
          '{{ 1 is in ((1, 2)) }}|'
          '{{ 3 is in ((1, 2)) }}|'
          '{{ 1 is in [1, 2] }}|'
          '{{ 3 is in [1, 2] }}|'
          '{{ "foo" is in {"foo": 1}}}|'
          '{{ "baz" is in {"bar": 1}}}');
      expect(template.render(),
          equals('true|true|false|true|false|true|false|true|false'));
    });
  });
}
