import 'package:test/test.dart';

import '../environment.dart';

const recursiveData = <String, List<Object>>{
  'seq': [
    {'a': 1, 'b': [{'a': 1}, {'a': 2}]},
    {'a': 2, 'b': [{'a': 1}, {'a': 2}]},
    {'a': 3, 'b': [{'a': 'a'}]},
  ]
};

void main() {
  group('For', () {
    test('simple', () {
      var tmpl = env.fromString('{% for item in seq %}{{ item }}{% endfor %}');
      expect(tmpl.render({'seq': range(10)}), equals('0123456789'));
    });

    test('else', () {
      var tmpl =
          env.fromString('{% for item in seq %}XXX{% else %}...{% endfor %}');
      expect(tmpl.render({'seq': range(0)}), equals('...'));
    });

    test('else scoping item', () {
      var tmpl = env
          .fromString('{% for item in [] %}{% else %}{{ item }}{% endfor %}');
      expect(tmpl.render({'item': 42}), equals('42'));
    });

    test('empty blocks', () {
      var tmpl =
          env.fromString('<{% for item in seq %}{% else %}{% endfor %}>');
      expect(tmpl.render({'seq': range(0)}), equals('<>'));
    });

    test('map tuple', () {
      final tmpl =
          env.fromString('{% for k, v in map %}<{{k}}:{{v}}>{% endfor %}');
      expect(tmpl.render({'map': {'a': 1, 'b': 2}}), equals('<a:1><b:2>'));
    });

    test('context vars', () {
      var slist = [42, 24];

      for (var seq in [slist, slist.reversed]) {
        var tmpl = env.fromString('''{% for item in seq -%}
            {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
                loop.revindex0 }}|{{ loop.first }}|{{ loop.last }}|{{
               loop.length }}###{% endfor %}''');
        var parts = tmpl.render({'seq': seq}).split('###');
        var one = parts[0].split('|');
        var two = parts[1].split('|');
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

    test('cycling', () {
      var tmpl = env.fromString('''{% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''');
      var output = tmpl.render({'seq': range(4), 'through': ['<1>', '<2>']});
      expect(output, equals('<1><2>' * 4));
    });

    test('lookaround', () {
      var tmpl = env.fromString('''{% for item in seq -%}
            {{ loop.previtem | default('x') }}-{{ item }}-{{
            loop.nextitem | default('x') }}|
        {%- endfor %}''');
      var output = tmpl.render({'seq': range(4)});
      expect(output, equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
    });

    test('changed', () {
      var tmpl = env.fromString('''{% for item in seq -%}
            {{ loop.changed(item) }},
        {%- endfor %}''');
      var output = tmpl.render({
        'seq': [null, null, 1, 2, 2, 3, 4, 4, 4]
      });
      expect(
          output, equals('true,false,true,true,false,true,true,false,false,'));
    });

    test('scope', () {
      var tmpl = env.fromString('{% for item in seq %}{% endfor %}{{ item }}');
      var output = tmpl.render({'seq': range(10)});
      expect(output, equals(''));
    });

    test('varlen', () {
      var tmpl = env.fromString('{% for item in iter %}{{ item }}{% endfor %}');
      var output = tmpl.render({'iter': range(5)});
      expect(output, equals('01234'));
    });

    test('noniter', () {
      var tmpl = env.fromString('{% for item in none %}...{% endfor %}');
      expect(() => tmpl.render(), throwsA(isA<TypeError>()));
    });

    test('recursive', () {
      var tmpl = env.fromString('''{% for item in seq recursive -%}
            [{{ item['a'] }}{% if item['b'] %}<{{ loop(item['b']) }}>{% endif %}]
        {%- endfor %}''');
      expect(
          tmpl.render(recursiveData), equals('[1<[1][2]>][2<[1][2]>][3<[a]>]'));
    });

    test('recursive lookaround', () {
      var template = env.fromString('''{% for item in seq recursive -%}
            [{{ loop.previtem['a'] if loop.previtem is defined else 'x' }}.{{
            item['a'] }}.{{ loop.nextitem['a'] if loop.nextitem is defined else 'x'
            }}{% if item['b'] %}<{{ loop(item['b']) }}>{% endif %}]
        {%- endfor %}''');
      expect(
          template.render(recursiveData),
          equals(
              '[x.1.2<[x.1.2][1.2.x]>][1.2.3<[x.1.2][1.2.x]>][2.3.x<[x.a.x]>]'));
    });

    test('recursive depth0', () {
      var tmpl = env.fromString('''{% for item in seq recursive -%}
        [{{ loop.depth0 }}:{{ item['a'] }}{% if item['b'] %}<{{ loop(item['b']) }}>{% endif %}]
        {%- endfor %}''');
      expect(tmpl.render(recursiveData),
          equals('[0:1<[1:1][1:2]>][0:2<[1:1][1:2]>][0:3<[1:a]>]'));
    });

    test('recursive depth', () {
      var tmpl = env.fromString('''{% for item in seq recursive -%}
        [{{ loop.depth }}:{{ item['a'] }}{% if item['b'] %}<{{ loop(item['b']) }}>{% endif %}]
        {%- endfor %}''');
      expect(tmpl.render(recursiveData),
          equals('[1:1<[2:1][2:2]>][1:2<[2:1][2:2]>][1:3<[2:a]>]'));
    });

    test('looploop', () {
      var tmpl = env.fromString('''{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}''');
      expect(
        tmpl.render({'table': ['ab', 'cd']}), equals('[1|1][1|2][2|1][2|2]'));
    });

    // TODO: add test: recursive bug
    // test('recursive bug', () {});

    test('loop errors', () {
      var tmpl = env.fromString(
          '{% for item in [1] if loop.index == 0 %}...{% endfor %}');
      expect(() => tmpl.render(), throwsA(isA<NoSuchMethodError>()));
      tmpl = env.fromString(
          '{% for item in [] %}...{% else %}{{ loop }}{% endfor %}');
      expect(tmpl.render(), equals(''));
    });

    test('loop filter', () {
      var tmpl = env.fromString(
          '{% for item in range(10) if item is even %}[{{ item }}]{% endfor %}');
      expect(tmpl.render(), equals('[0][2][4][6][8]'));
      tmpl = env.fromString('''
            {%- for item in range(10) if item is even %}[{{
                loop.index }}:{{ item }}]{% endfor %}''');
      expect(tmpl.render(), equals('[1:0][2:2][3:4][4:6][5:8]'));
    });

    test('loop unassignable', () {
      expect(() => env.fromString('{% for loop in seq %}...{% endfor %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('scoped special var', () {
      var tmpl =
          env.fromString('{% for s in seq %}[{{ loop.first }}{% for c in s %}'
              '|{{ loop.first }}{% endfor %}]{% endfor %}');
      expect(
          tmpl.render({'seq': ['ab', 'cd']}),
          equals('[true|true|false][false|true|false]'));
    });

    test('scoped loop var', () {
      var tmpl = env.fromString('{% for x in seq %}{{ loop.first }}'
          '{% for y in seq %}{% endfor %}{% endfor %}');
      expect(tmpl.render({'seq': 'ab'}), 'truefalse');
      tmpl = env.fromString('{% for x in seq %}{% for y in seq %}'
          '{{ loop.first }}{% endfor %}{% endfor %}');
      expect(tmpl.render({'seq': 'ab'}), equals('truefalsetruefalse'));
    });

    test('recursive empty loop iter', () {
      var tmpl = env.fromString('{% for item in foo recursive %}{% endfor %}');
      expect(tmpl.render({'foo': range(0)}), equals(''));
    });

    // TODO: after macro: add tests: call in loop
    // TODO: after macro: add tests: scoping bug

    test('unpacking', () {
      var tmpl = env.fromString('{% for a, b, c in [[1, 2, 3]] %}'
          '{{ a }}|{{ b }}|{{ c }}{% endfor %}');
      expect(tmpl.render(), equals('1|2|3'));
    });

    test('intended scoping with set', () {
      var data = {'x': 0, 'seq': [1, 2, 3]};
      var tmpl = env.fromString('{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      expect(tmpl.render(data), equals('010203'));
      tmpl = env.fromString('{% set x = 9 %}{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      expect(tmpl.render(data), equals('919293'));
    });
  });
}
