import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  final env = Environment();

  test('simple', () {
    final template =
        env.fromSource('{% for item in seq %}{{ item }}{% endfor %}');
    expect(template.testRender(seq: range(10)), equals('0123456789'));
  });

  test('else', () {
    final template =
        env.fromSource('{% for item in seq %}XXX{% else %}...{% endfor %}');
    expect(template.testRender(), equals('...'));
  });

  test('else scoping item', () {
    final template =
        env.fromSource('{% for item in [] %}{% else %}{{ item }}{% endfor %}');
    expect(template.testRender(item: 42), equals('42'));
  });

  test('empty blocks', () {
    final template =
        env.fromSource('<{% for item in seq %}{% else %}{% endfor %}>');
    expect(template.testRender(), equals('<>'));
  });

  test('context vars', () {
    final slist = [42, 24];
    Template template;

    for (var seq in [slist, slist.reversed]) {
      template = env.fromSource('''{% for item in seq -%}
            {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
                loop.revindex0 }}|{{ loop.first }}|{{ loop.last }}|{{
               loop.length }}###{% endfor %}''');

      final parts = template.testRender(seq: seq).split('###');
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

  test('cycling', () {
    final template = env.fromSource('''{% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''');
    expect(template.testRender(seq: range(4), through: ['<1>', '<2>']),
        equals('<1><2>' * 4));
  });

  test('lookaround', () {
    final template = env.fromSource('''{% for item in seq -%}
            {{ loop.previtem|default('x') }}-{{ item }}-{{
            loop.nextitem|default('x') }}|
        {%- endfor %}''');
    expect(
        template.testRender(seq: range(4)), equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
  });

  test('changed', () {
    final template = env.fromSource('''{% for item in seq -%}
            {{ loop.changed(item) }},
        {%- endfor %}''');
    expect(template.testRender(seq: [null, null, 1, 2, 2, 3, 4, 4, 4]),
        equals('true,false,true,true,false,true,true,false,false,'));
  });

  test('scope', () {
    final template =
        env.fromSource('{% for item in seq %}{% endfor %}{{ item }}');
    expect(template.testRender(seq: range(10)), equals(''));
  });

  test('varlen', () {
    final template =
        env.fromSource('{% for item in iter %}{{ item }}{% endfor %}');

    Iterable<int> inner() sync* {
      for (var i = 0; i < 5; i++) yield i;
    }

    expect(template.testRender(iter: inner()), equals('01234'));
  });

  test('noniter', () {
    final template = env.fromSource('{% for item in none %}...{% endfor %}');
    expect(() => template.testRender(), throwsArgumentError);
  });

  // TODO: test recursive
  // TODO: test recursive lookaround
  // TODO: test recursive depth0
  // TODO: test recursive depth

  test('looploop', () {
    final template = env.fromSource('''{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}''');
    expect(template.testRender(table: ['ab', 'cd']), '[1|1][1|2][2|1][2|2]');
  });

  // TODO: test reversed bug
  // TODO: test loop errors

  test('loop filter', () {
    var template = env.fromSource('{% for item in range(10) if item '
        'is even %}[{{ item }}]{% endfor %}');
    expect(template.testRender(), '[0][2][4][6][8]');
    template = env.fromSource('''
            {%- for item in range(10) if item is even %}[{{
                loop.index }}:{{ item }}]{% endfor %}''');
    expect(template.testRender(), '[1:0][2:2][3:4][4:6][5:8]');
  });

  // TODO: test loop unassignable
  // TODO: test scoped special var
  // TODO: test scoped loop var
  // TODO: test recursive empty loop iter
  // TODO: test call in loop
  // TODO: test scoping bug

  test('unpacking', () {
    final template = env.fromSource('{% for a, b, c in [[1, 2, 3]] %}'
        '{{ a }}|{{ b }}|{{ c }}{% endfor %}');
    expect(template.testRender(), '1|2|3');
  });

  test('intended scoping with set', () {
    var template = env.fromSource('{% for item in seq %}{{ x }}'
        '{% set x = item %}{{ x }}{% endfor %}');
    expect(template.testRender(x: 0, seq: [1, 2, 3]), '010203');
    template = env.fromSource('{% set x = 9 %}{% for item in seq %}{{ x }}'
        '{% set x = item %}{{ x }}{% endfor %}');
    expect(template.testRender(x: 0, seq: [1, 2, 3]), '919293');
  });
}
