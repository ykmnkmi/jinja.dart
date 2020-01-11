import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('for', () {
    final Environment env = Environment();

    test('simple', () {
      final Template template =
          env.fromString('{% for item in seq %}{{ item }}{% endfor %}');
      expect(template.render(seq: range(10)), equals('0123456789'));
    });

    test('else', () {
      final Template template =
          env.fromString('{% for item in seq %}XXX{% else %}...{% endfor %}');
      expect(template.renderMap(), equals('...'));
    });

    test('else scoping item', () {
      final Template template = env
          .fromString('{% for item in [] %}{% else %}{{ item }}{% endfor %}');
      expect(template.render(item: 42), equals('42'));
    });

    test('empty blocks', () {
      final Template template =
          env.fromString('<{% for item in seq %}{% else %}{% endfor %}>');
      expect(template.renderMap(), equals('<>'));
    });

    test('context vars', () {
      final List<int> slist = <int>[42, 24];
      Template template;

      for (Iterable<int> seq in <Iterable<int>>[slist, slist.reversed]) {
        template = env.fromString('''{% for item in seq -%}
            {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
                loop.revindex0 }}|{{ loop.first }}|{{ loop.last }}|{{
               loop.length }}###{% endfor %}''');

        final List<String> parts =
            template.renderMap(<String, Object>{'seq': seq}).split('###');
        final List<String> one = parts[0].split('|');
        final List<String> two = parts[1].split('|');

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
      final Template template = env.fromString('''{% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''');
      expect(template.render(seq: range(4), through: <String>['<1>', '<2>']),
          equals('<1><2>' * 4));
    });

    test('lookaround', () {
      final Template template = env.fromString('''{% for item in seq -%}
            {{ loop.previtem|default('x') }}-{{ item }}-{{
            loop.nextitem|default('x') }}|
        {%- endfor %}''');
      expect(
          template.render(seq: range(4)), equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
    });

    test('changed', () {
      final Template template = env.fromString('''{% for item in seq -%}
            {{ loop.changed(item) }},
        {%- endfor %}''');
      expect(template.render(seq: <int>[null, null, 1, 2, 2, 3, 4, 4, 4]),
          equals('true,false,true,true,false,true,true,false,false,'));
    });

    test('scope', () {
      final Template template =
          env.fromString('{% for item in seq %}{% endfor %}{{ item }}');
      expect(template.render(seq: range(10)), equals(''));
    });

    test('varlen', () {
      final Template template =
          env.fromString('{% for item in iter %}{{ item }}{% endfor %}');

      Iterable<int> inner() sync* {
        for (int i = 0; i < 5; i++) {
          yield i;
        }
      }

      expect(template.render(iter: inner()), equals('01234'));
    });

    test('noniter', () {
      final Template template =
          env.fromString('{% for item in none %}...{% endfor %}');
      expect(() => template.renderMap(), throwsArgumentError);
    });

    // TODO: добавить тест: recursive
    // TODO: добавить тест: recursive lookaround
    // TODO: добавить тест: recursive depth0
    // TODO: добавить тест: recursive depth

    test('looploop', () {
      final Template template = env.fromString('''{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}''');
      expect(
          template.render(table: <String>['ab', 'cd']), '[1|1][1|2][2|1][2|2]');
    });

    test('reversed bug', () {
      final Template template = env.fromString('{% for i in items %}{{ i }}'
          '{% if not loop.last %}'
          ',{% endif %}{% endfor %}');
      expect(template.render(items: <int>[3, 2, 1].reversed), '1,2,3');
    });

    test('loop errors', () {
      final Template template =
          env.fromString('''{% for item in [1] if loop.index
                                      == 0 %}...{% endfor %}''');
      expect(() => template.renderMap(), throwsA(isA<UndefinedError>()));
    });

    test('loop filter', () {
      Template template = env.fromString('{% for item in range(10) if item '
          'is even %}[{{ item }}]{% endfor %}');
      expect(template.renderMap(), '[0][2][4][6][8]');
      template = env.fromString('''
            {%- for item in range(10) if item is even %}[{{
                loop.index }}:{{ item }}]{% endfor %}''');
      expect(template.renderMap(), '[1:0][2:2][3:4][4:6][5:8]');
    });

    // TODO: добавить тест: loop unassignable

    test('scoped special var', () {
      final Template template =
          env.fromString('{% for s in seq %}[{{ loop.first }}{% for c in s %}'
              '|{{ loop.first }}{% endfor %}]{% endfor %}');
      expect(template.render(seq: <String>['ab', 'cd']),
          '[true|true|false][false|true|false]');
    });

    test('scoped loop var', () {
      Template template = env.fromString('{% for x in seq %}{{ loop.first }}'
          '{% for y in seq %}{% endfor %}{% endfor %}');
      final Map<String, Object> data = <String, Object>{'seq': 'ab'};

      expect(template.renderMap(data), 'truefalse');
      template = env.fromString('{% for x in seq %}{% for y in seq %}'
          '{{ loop.first }}{% endfor %}{% endfor %}');
      expect(template.renderMap(data), 'truefalsetruefalse');
    });

    // TODO: добавить тест: recursive empty loop iter
    // TODO: добавить тест: call in loop
    // TODO: добавить тест: scoping bug

    test('unpacking', () {
      final Template template =
          env.fromString('{% for a, b, c in [[1, 2, 3]] %}'
              '{{ a }}|{{ b }}|{{ c }}{% endfor %}');
      expect(template.renderMap(), '1|2|3');
    });

    test('intended scoping with set', () {
      Template template = env.fromString('{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      final Map<String, Object> data = <String, Object>{
        'x': 0,
        'seq': <int>[1, 2, 3]
      };

      expect(template.renderMap(data), '010203');
      template = env.fromString('{% set x = 9 %}{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      expect(template.renderMap(data), '919293');
    });
  });
}
