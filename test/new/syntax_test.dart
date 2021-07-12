import 'package:jinja/jinja.dart';
import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

import 'environment.dart';

class Foo {
  Object? operator [](Object? key) {
    return key;
  }
}

void main() {
  group('Syntax', () {
    test('call', () {
      final environment = Environment(
        globals: {
          'foo': (dynamic a, dynamic b, {dynamic c, dynamic e, dynamic g}) =>
              a + b + c + e + g,
        },
      );

      expect(
          environment
              .fromString('{{ foo("a", c="d", e="f", *["b"], **{"g": "h"}) }}')
              .render(),
          equals('abdfh'));
    });

    test('slicing', () {
      expect(render('{{ [1, 2, 3][:] }}|{{ [1, 2, 3][::-1] }}'),
          equals('[1, 2, 3]|[3, 2, 1]'));
    });

    test('attr', () {
      expect(
          render('{{ foo.bar }}|{{ foo["bar"] }}', {
            'foo': {'bar': 42}
          }),
          equals('42|42'));
    });

    test('subscript', () {
      expect(
          render('{{ foo[0] }}|{{ foo[-1] }}', {
            'foo': [0, 1, 2]
          }),
          equals('0|2'));
    });

    test('tuple', () {
      // tuple is list
      expect(
          render('{{ () }}|{{ (1,) }}|{{ (1, 2) }}'), equals('[]|[1]|[1, 2]'));
    });

    test('math', () {
      expect(render('{{ (1 + 1 * 2) - 3 / 2 }}|{{ 2**3 }}'), equals('1.5|8'));
    });

    test('div', () {
      expect(render('{{ 3 // 2 }}|{{ 3 / 2 }}|{{ 3 % 2 }}'), equals('1|1.5|1'));
    });

    test('unary', () {
      expect(render('{{ +3 }}|{{ -3 }}'), equals('3|-3'));
    });

    test('concat', () {
      expect(render('{{ [1, 2] ~ "foo" }}'), equals('[1, 2]foo'));
    });

    test('compare', () {
      expect(render('{{ 1 > 0 }}'), equals('true'));
      expect(render('{{ 1 >= 1 }}'), equals('true'));
      expect(render('{{ 2 < 3 }}'), equals('true'));
      expect(render('{{ 3 <= 4 }}'), equals('true'));
      expect(render('{{ 4 == 4 }}'), equals('true'));
      expect(render('{{ 4 != 5 }}'), equals('true'));
    });

    test('compare parens', () {
      // num * bool not supported
      // '{{ i * (j < 5) }}'
      expect(parse('{{ i == (j < 5) }}').render({'i': 2, 'j': 3}),
          equals('false'));
    });

    test('compare compound', () {
      final data = {'a': 4, 'b': 2, 'c': 3};
      expect(render('{{ 4 < 2 < 3 }}', data), equals('false'));
      expect(render('{{ a < b < c }}', data), equals('false'));
      expect(render('{{ 4 > 2 > 3 }}', data), equals('false'));
      expect(render('{{ a > b > c }}', data), equals('false'));
      expect(render('{{ 4 > 2 < 3 }}', data), equals('true'));
      expect(render('{{ a > b < c }}', data), equals('true'));
    });

    test('inop', () {
      expect(parse('{{ 1 in [1, 2, 3] }}|{{ 1 not in [1, 2, 3] }}').render(),
          equals('true|false'));
    });

    test('collection literal', () {
      expect(render('{{ [] }}'), equals('[]'));
      expect(render('{{ {} }}'), equals('{}'));
      // tuple is list
      expect(render('{{ () }}'), equals('[]'));
    });

    test('numeric literal', () {
      expect(render('{{ 1 }}'), equals('1'));
      expect(render('{{ 123 }}'), equals('123'));
      expect(render('{{ 12_34_56 }}'), equals('123456'));
      expect(render('{{ 1.2 }}'), equals('1.2'));
      expect(render('{{ 34.56 }}'), equals('34.56'));
      expect(render('{{ 3_4.5_6 }}'), equals('34.56'));
      expect(render('{{ 1e0 }}'), equals('1.0'));
      expect(render('{{ 10e1 }}'), equals('100.0'));
      expect(render('{{ 2.5e100 }}'), equals('2.5e+100'));
      expect(render('{{ 2.5e+100 }}'), equals('2.5e+100'));
      // difference '2.56e-09'
      expect(render('{{ 25.6e-10 }}'), equals('2.56e-9'));
      expect(render('{{ 1_2.3_4e5_6 }}'), equals('1.234e+57'));
    });

    test('bool', () {
      expect(render('{{ true and false }}|{{ false or true }}|{{ not false }}'),
          equals('false|true|true'));
    });

    test('grouping', () {
      expect(render('{{ (true and false) or (false and true) and not false }}'),
          equals('false'));
    });

    test('django attr', () {
      expect(render('{{ [1, 2, 3].0 }}|{{ [[1]].0.0 }}'), equals('1|1'));
    });

    test('conditional expression', () {
      expect(render('{{ 0 if true else 1 }}'), equals('0'));
    });

    test('short conditional expression', () {
      expect(render('<{{ 1 if false }}>'), equals('<>'));
    });

    test('filter priority', () {
      expect(render('{{ "foo" | upper + "bar" | upper }}'), equals('FOOBAR'));
    });

    test('function calls', () {
      expect(() => parse('{{ foo(*foo, bar) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(() => parse('{{ foo(*foo, *bar) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(() => parse('{{ foo(**foo, *bar) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(() => parse('{{ foo(**foo, bar) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(() => parse('{{ foo(**foo, **bar) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(() => parse('{{ foo(**foo, bar=42) }}'),
          equals(throwsA(isA<TemplateSyntaxError>())));
      expect(parse('{{ foo(foo, bar) }}'), isA<Template>());
      expect(parse('{{ foo(foo, bar=42) }}'), isA<Template>());
      expect(parse('{{ foo(foo, bar=23, *args) }}'), isA<Template>());
      expect(parse('{{ foo(foo, *args, bar=23) }}'), isA<Template>());
      expect(parse('{{ foo(a, b=c, *d, **e) }}'), isA<Template>());
      expect(parse('{{ foo(*foo, bar=42) }}'), isA<Template>());
      expect(parse('{{ foo(*foo, **bar) }}'), isA<Template>());
      expect(parse('{{ foo(*foo, bar=42, **baz) }}'), isA<Template>());
      expect(parse('{{ foo(foo, *args, bar=23, **baz) }}'), isA<Template>());
    });

    test('tuple expr', () {
      expect(parse('{{ () }}'), isA<Template>());
      expect(parse('{{ (1, 2) }}'), isA<Template>());
      expect(parse('{{ (1, 2,) }}'), isA<Template>());
      expect(parse('{{ 1, }}'), isA<Template>());
      expect(parse('{{ 1, 2 }}'), isA<Template>());
      expect(
          parse('{% for foo, bar in seq %}...{% endfor %}'), isA<Template>());
      expect(parse('{% for x in foo, bar %}...{% endfor %}'), isA<Template>());
      expect(parse('{% for x in foo, %}...{% endfor %}'), isA<Template>());
    });

    test('triling comma', () {
      // tuple is list
      expect(render('{{ (1, 2,) }}|{{ [1, 2,] }}|{{ {1: 2,} }}'),
          equals('[1, 2]|[1, 2]|{1: 2}'));
    });

    test('block end name', () {
      expect(parse('{% block foo %}...{% endblock foo %}'), isA<Template>());
      expect(() => parse('{% block x %}{% endblock y %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('string concatenation', () {
      expect(render('{{ "foo" "bar" "baz" }}'), equals('foobarbaz'));
    });

    test('notin', () {
      expect(
          render('{{ not 42 in bar }}', {'bar': range(100)}), equals('false'));
    });

    test('operator precedence', () {
      expect(render('{{ 2 * 3 + 4 % 2 + 1 - 2 }}'), equals('5'));
    });

    test('implicit subscribed tuple', () {
      // tuple is list
      expect(render('{{ foo[1, 2] }}', {'foo': Foo()}), equals('[1, 2]'));
    });

    test('raw2', () {
      // tuple is list
      expect(render('{% raw %}{{ FOO }} and {% BAR %}{% endraw %}'),
          equals('{{ FOO }} and {% BAR %}'));
    });

    test('const', () {
      expect(
          render('{{ true }}|{{ false }}|{{ none }}|{{ none is defined }}|'
              '{{ missing is defined }}'),
          equals('true|false|null|true|false'));
    });

    test('neg filter priority', () {
      final template = parse('{{ -1 | foo }}');
      final output = template.nodes[0] as Output;
      expect(output.nodes[0],
          predicate<Filter>((filter) => filter.expression is Neg));
    });

    test('const assign', () {
      expect(() => parse('{% set true = 42 %}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => parse('{% for none in seq %}{% endfor %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('localset', () {
      expect(
          render('{% set foo = 0 %}{% for item in [1, 2] %}{% set foo = 1 %}'
              '{% endfor %}{{ foo }}'),
          equals('0'));
    });

    test('parse unary', () {
      final data = {
        'foo': {'bar': 42}
      };
      expect(render('{{ -foo["bar"] }}', data), equals('-42'));
      expect(render('{{ foo["bar"] }}', data), equals('42'));
    });
  });
}
