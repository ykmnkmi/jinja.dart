import 'dart:math' show Point, pow;

import 'package:jinja/jinja.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

// From https://github.com/pallets/jinja/blob/master/tests/test_filters.py

void main() {
  group('Filter', () {
    final env = Environment();

    test('Filter Calling', () {
      expect(
          env.callFilter('sum', [
            [1, 2, 3]
          ]),
          equals(6));
    });

    test('Capitalize', () {
      final template = env.fromSource('{{ "foo bar" | capitalize }}');

      expect(template.render(), equals('Foo bar'));
    });

    test('Center', () {
      final template = env.fromSource('{{ "foo" | center(9) }}');

      expect(template.render(), equals('   foo   '));
    });

    test('Default', () {
      final template = env.fromSource('{{ missing | default("no") }}'
          '|{{ false | default("no") }}|{{ false | default("no", true) }}|'
          '{{ given | default("no") }}');

      expect(template.render({'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('Dict Sort', () {
      final args = [
        ['', '[[aa, 0], [AB, 3], [b, 1], [c, 2]]'],
        ['caseSensetive=true', '[[AB, 3], [aa, 0], [b, 1], [c, 2]]'],
        ['by="value"', '[[aa, 0], [b, 1], [c, 2], [AB, 3]]'],
        ['reverse=true', '[[c, 2], [b, 1], [AB, 3], [aa, 0]]']
      ];
      for (final arg in args) {
        final template = env.fromSource('{{ foo | dictsort(${arg[0]}) }}');

        expect(
            template.render({
              'foo': {'aa': 0, 'b': 1, 'c': 2, 'AB': 3}
            }),
            equals(arg[1]));
      }
    });

    test('Batch', () {
      final template = env.fromSource('{{ foo | batch(3) | list }}|'
          '{{ foo | batch(3, "X") | list }}');

      expect(
          template.render({'foo': range(10)}),
          equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|'
              '[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    test('Escape', () {
      final template = env.fromSource('{{ \'<">&\' | escape }}');

      expect(template.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('File Size Format', () {
      final template = env.fromSource('{{ 100 | filesizeformat }}|'
          '{{ 1000 | filesizeformat }}|'
          '{{ 1000000 | filesizeformat }}|'
          '{{ 1000000000 | filesizeformat }}|'
          '{{ 1000000000000 | filesizeformat }}|'
          '{{ 100 | filesizeformat(true) }}|'
          '{{ 1000 | filesizeformat(true) }}|'
          '{{ 1000000 | filesizeformat(true) }}|'
          '{{ 1000000000 | filesizeformat(true) }}|'
          '{{ 1000000000000 | filesizeformat(true) }}');

      expect(
          template.render(),
          equals('100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|'
              '1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB'));
    });

    test('File Size Format Issue 59', () {
      final template = env.fromSource('{{ 300 | filesizeformat }}|'
          '{{ 3000 | filesizeformat }}|'
          '{{ 3000000 | filesizeformat }}|'
          '{{ 3000000000 | filesizeformat }}|'
          '{{ 3000000000000 | filesizeformat }}|'
          '{{ 300 | filesizeformat(true) }}|'
          '{{ 3000 | filesizeformat(true) }}|'
          '{{ 3000000 | filesizeformat(true) }}');

      expect(
          template.render(),
          equals('300 Bytes|3.0 kB|3.0 MB|3.0 GB|3.0 TB|300 Bytes|'
              '2.9 KiB|2.9 MiB'));
    });

    test('First', () {
      final template = env.fromSource('{{ foo | first }}');

      expect(template.render({'foo': range(10)}), equals('0'));
    });

    test('Float', () {
      final template = env.fromSource('{{ "42" | float }}|'
          '{{ "ajsghasjgd" | float }}|'
          '{{ "32.32" | float }}');

      expect(template.render(), equals('42.0|0.0|32.32'));
    });

    test('Int', () {
      final template = env.fromSource('{{ "42" | int }}|'
          '{{ "ajsghasjgd" | int }}|{{ "32.32" | int }}|'
          '{{ "0x4d32" | int(0, 16) }}|{{ "011" | int(0, 8)}}|'
          '{{ "0x33FU" | int(0, 16) }}');

      expect(template.render(), equals('42|0|32|19762|9|0'));
    });

    test('Join', () {
      final template = env.fromSource('{{ [1, 2, 3] | join("|") }}');

      expect(template.render(), equals('1|2|3'));
    });

    test('Join Attribute', () {
      final template = env.fromSource('{{ points | join("|", "y") }}');

      expect(
          template.render({
            'points': range(3)
                .map<Point<num>>((i) => Point<num>(i, pow(i, 2)))
                .toList(growable: false)
          }),
          equals('0|1|4'));
    });

    test('Last', () {
      final template = env.fromSource('{{ foo | last }}');

      expect(template.render({'foo': range(10)}), equals('9'));
    });

    test('Length', () {
      final template = env.fromSource('{{ "hello world" | length }}');

      expect(template.render(), equals('11'));
    });

    test('Lower', () {
      final template = env.fromSource('{{ "FOO" | lower }}');

      expect(template.render(), equals('foo'));
    });

    test('Upper', () {
      final template = env.fromSource('{{ "foo" | upper }}');

      expect(template.render(), equals('FOO'));
    });

    test('Chaining', () {
      final template =
          env.fromSource('{{ ["<foo>", "<bar>"] | first | upper | escape }}');

      expect(template.render(), equals('&lt;FOO&gt;'));
    });

    test('Sum', () {
      final template = env.fromSource('{{ [1, 2, 3, 4, 5, 6] | sum }}');

      expect(template.render(), equals('21'));
    });

    test('Sum Attributes', () {
      final template = env.fromSource('{{ values | sum("value") }}');

      expect(
          template.render({
            'values': [
              {'value': 23},
              {'value': 1},
              {'value': 18},
            ]
          }),
          equals('42'));
    });

    test('Sum Attributes Nested', () {
      final template = env.fromSource('{{ values | sum("real.value") }}');

      expect(
          template.render({
            'values': [
              {
                'real': {'value': 23}
              },
              {
                'real': {'value': 1}
              },
              {
                'real': {'value': 18}
              },
            ]
          }),
          equals('42'));
    });

    test('Abs', () {
      final template = env.fromSource('{{ -1 | abs }}|{{ 1 | abs }}');

      expect(template.render(), equals('1|1'));
    });

    test('Force Escape', () {
      final template = env.fromSource('{{  x | forceescape  }}');

      expect(template.render({'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });
  });
}
