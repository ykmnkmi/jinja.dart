import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import "package:test/test.dart";

// From https://github.com/pallets/jinja/blob/master/tests/test_core_tags.py

void main() {
  group('For', () {
    final env = Environment();

    test("Simple", () {
      final template = env.fromSource('{% for item in seq %}{{ item }}'
          '{% endfor %}');

      expect(template.render({'seq': range(10)}), equals('0123456789'));
    });

    test("Else", () {
      final template = env.fromSource('{% for item in seq %}XXX{% else %}'
          '...{% endfor %}');

      expect(template.render(), equals('...'));
    });

    test("Else Scoping Item", () {
      final template = env.fromSource('{% for item in [] %}{% else %}'
          '{{ item }}{% endfor %}');

      expect(template.render({'item': 42}), equals('42'));
    });

    test("Empty Blocks", () {
      final template = env.fromSource('<{% for item in seq %}{% else %}'
          '{% endfor %}>');

      expect(template.render(), equals('<>'));
    });

    test("Context Vars", () {
      final slist = [42, 24];

      Template template;
      for (final seq in [slist, slist.reversed]) {
        template = env.fromSource('{% for item in seq %}{{ loop.index }}|'
            '{{ loop.index0 }}|{{ loop.revindex }}|{{loop.revindex0 }}|'
            '{{ loop.first }}|{{ loop.last }}|{{ loop.length }}###'
            '{% endfor %}');

        final parts = template.render({'seq': seq}).split('###');
        final one = parts[0].split('|');
        final two = parts[1].split('|');

        expect(one[0], equals('1'));
        expect(one[1], equals('0'));
        expect(one[2], equals('2'));
        expect(one[3], equals('1'));
        expect(one[4], equals('true'));
        expect(one[5], equals('false'));
        expect(one[6], equals('2'));

        expect(two[0], equals('2'));
        expect(two[1], equals('1'));
        expect(two[2], equals('1'));
        expect(two[3], equals('0'));
        expect(two[4], equals('false'));
        expect(two[5], equals('true'));
        expect(two[6], equals('2'));
      }
    });

    test("Cycling", () {
      final template = env.fromSource('{% for item in seq %}'
          '{{ loop.cycle("<1>", "<2>") }}{% endfor %}{% for item in seq %}'
          '{{ loop.cycle(*through) }}{% endfor %}');

      expect(
          template.render({
            'seq': range(4),
            'through': ['<1>', '<2>']
          }),
          equals('<1><2>' * 4));
    });

    test("Look Around", () {
      final template = env.fromSource('{% for item in seq %}'
          '{{ loop.previtem | default("x") }}-{{ item }}-{{'
          'loop.nextitem | default("x") }}|{% endfor %}');

      expect(template.render({'seq': range(4)}),
          equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
    });

    test("Changed", () {
      final template = env.fromSource('{% for item in seq %}'
          '{{ loop.changed(item) }},{% endfor %}');

      expect(
          template.render({
            'seq': [null, null, 1, 2, 2, 3, 4, 4, 4]
          }),
          equals('true,false,true,true,false,true,true,false,false,'));
    });

    test("Scope", () {
      final template = env.fromSource('{% for item in seq %}{% endfor %}'
          '{{ item }}');

      expect(template.render({'seq': range(10)}), equals(''));
    });

    test("Var Length", () {
      final template = env.fromSource('{% for item in iter %}{{ item }}'
          '{% endfor %}');

      Iterable<int> inner() sync* {
        for (var i = 0; i < 5; i++) yield i;
      }

      expect(template.render({'iter': inner()}), equals('01234'));
    });

    test("Non Iterable", () {
      final template = env.fromSource('{% for item in none %}...{% endfor %}');
      expect(template.render, throwsArgumentError);
    });

    test("Recursive", () {
      final template = env.fromSource('{% for item in seq recursive %}'
          '[{{ item["a"] }}{% if item["b"] %}<{{ loop(item["b"]) }}>'
          '{% endif %}]{% endfor %}');

      expect(
          template.render({
            'seq': [
              {
                'a': 1,
                'b': [
                  {'a': 1},
                  {'a': 2},
                ]
              },
              {
                'a': 2,
                'b': [
                  {'a': 1},
                  {'a': 2},
                ],
              },
              {
                'a': 3,
                'b': [
                  {'a': 'a'},
                ],
              },
            ],
          }),
          equals('[1<[1][2]>][2<[1][2]>][3<[a]>]'));
    });

    // test("Recursive Look Around", () {
    //   Template template = env.fromSource('{% for item in seq recursive %}'
    //       '[{{ loop.previtem.a if loop.previtem is defined else "x" }}.{{'
    //       'item.a }}.{{ loop.nextitem.a if loop.nextitem is defined else "x"'
    //       '}}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]'
    //       '{% endfor %}');

    //   expect(
    //       template.render({
    //         'seq': [
    //           {
    //             'a': 1,
    //             'b': [
    //               {'a': 1},
    //               {'a': 2},
    //             ]
    //           },
    //           {
    //             'a': 2,
    //             'b': [
    //               {'a': 1},
    //               {'a': 2},
    //             ],
    //           },
    //           {
    //             'a': 3,
    //             'b': [
    //               {'a': 'a'},
    //             ],
    //           },
    //         ],
    //       }),
    //       equals('[0:1<[1:1][1:2]>][0:2<[1:1][1:2]>][0:3<[1:a]>]'));
    // });
  });

  group('If', () {
    final env = Environment();

    test("Simple", () {
      final template = env.fromSource('{% if true %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test("Elif", () {
      final template = env.fromSource('{% if false %}XXX{% elif true %}...'
          '{% else %}XXX{% endif %}');

      expect(template.render(), equals('...'));
    });

    test("Elif Deep", () {
      final source = '{% if a == 0 %}0' +
          List.generate(1000, (i) => '{% elif a == $i %}$i', growable: false)
              .join() +
          '{% else %}x{% endif %}';
      final template = env.fromSource(source);

      expect(template.render({'a': 0}), equals('0'));
      expect(template.render({'a': 10}), equals('10'));
      expect(template.render({'a': 999}), equals('999'));
      expect(template.render({'a': 1000}), equals('x'));
    });

    test("Else", () {
      final template = env.fromSource('{% if false %}XXX{% else %}...'
          '{% endif %}');

      expect(template.render(), equals('...'));
    });

    test("Empty", () {
      final template = env.fromSource('[{% if true %}{% else %}{% endif %}]');
      expect(template.render(), equals('[]'));
    });

    test("Complete", () {
      final template = env.fromSource(
          '{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}');

      expect(template.render({'a': 0, 'b': false, 'c': 42, 'd': 42.0}),
          equals('C'));
    });

    test("No Scope", () {
      var template = env.fromSource('{% if a %}{% set foo = 1 %}{% endif %}'
          '{{ foo }}');
      expect(template.render({'a': true}), equals('1'));

      template = env.fromSource('{% if true %}{% set foo = 1 %}{% endif %}'
          '{{ foo }}');
      expect(template.render(), equals('1'));
    });
  });

  group('Set', () {
    final env = Environment();

    test("Normal", () {
      final template = env.fromSource('{% set foo = 1 %}{{ foo }}');
      expect(template.render(), equals('1'));
    });
  });
}
