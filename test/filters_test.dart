import 'dart:math';

import 'package:jinja/jinja.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('filter', () {
    final env = Environment();

    test('chaining', () {
      final template =
          env.fromString('{{ ["<foo>", "<bar>"] | first | upper | escape }}');
      expect(template.render(), equals('&lt;FOO&gt;'));
    });

    test('capitalize', () {
      final template = env.fromString('{{ "foo bar" | capitalize }}');
      expect(template.render(), equals('Foo bar'));
    });

    test('center', () {
      final template = env.fromString('{{ "foo" | center(9) }}');
      expect(template.render(), equals('   foo   '));
    });

    test('count', () {
      final template = env.fromString('{{ "hello world" | count }}');
      expect(template.render(), equals('11'));
    });

    test('default', () {
      final template = env.fromString('{{ missing | default("no") }}'
          '|{{ false | default("no") }}|{{ false | default("no", true) }}|'
          '{{ given | default("no") }}');
      expect(template.render({'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('escape', () {
      final template = env.fromString('{{ \'<">&\' | escape }}');
      expect(template.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('first', () {
      final template = env.fromString('{{ foo | list | first }}');
      expect(template.render({'foo': range(10)}), equals('0'));
    });

    test('force escape', () {
      final template = env.fromString('{{  x | forceescape  }}');
      expect(
          template.render({'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });

    test('join', () {
      final template = env.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.render(), equals('1|2|3'));
    });

    test('join attribute', () {
      final template = env.fromString('{{ points | join("|", "y") }}');
      expect(
          template.render({
            'points': range(3)
                .map<Point<num>>((i) => Point<num>(i, pow(i, 2)))
                .toList(growable: false)
          }),
          equals('0|1|4'));
    });

    test('last', () {
      final template = env.fromString('{{ foo | list | last }}');
      expect(template.render({'foo': range(10)}), equals('9'));
    });

    test('lower', () {
      final template = env.fromString('{{ "FOO" | lower }}');

      expect(template.render(), equals('foo'));
    });

    test('upper', () {
      final template = env.fromString('{{ "foo" | upper }}');

      expect(template.render(), equals('FOO'));
    });
  });
}
