import 'dart:collection';

import 'package:jinja/jinja.dart';
import 'package:jinja/parser.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class Foo extends MapMixin<Object?, Object?> {
  @override
  Iterable<Object?> get keys {
    throw UnimplementedError();
  }

  @override
  Object? operator [](Object? key) {
    return key;
  }

  @override
  void operator []=(Object? key, Object? value) {}

  @override
  void clear() {
    throw UnimplementedError();
  }

  @override
  Object? remove(Object? key) {
    throw UnimplementedError();
  }
}

void main() {
  group('Syntax', () {
    test('call', () {
      Object? foo(dynamic a, {dynamic b}) => a + b;
      var env = Environment(globals: {'foo': foo});
      var tmpl = env.fromString('{{ foo(*["a"], **{"b": "c"}) }}');
      expect(tmpl.render(), equals('ac'));
    });

    test('attribute', () {
      var foo = {'bar': 42};
      var env = Environment(getAttribute: getAttribute);
      var tmpl = env.fromString('{{ foo.bar }}|{{ foo["bar"] }}');
      expect(tmpl.render({'foo': foo}), equals('42|42'));
    });

    test('subscript', () {
      var foo = [0, 1, 2];
      var tmpl = env.fromString('{{ foo[0] }}');
      expect(tmpl.render({'foo': foo}), equals('0'));
    });

    test('tuple', () {
      // tuple is list
      var tmpl = env.fromString('{{ () }}|{{ (1,) }}|{{ (1, 2) }}');
      expect(tmpl.render(), equals('[]|[1]|[1, 2]'));
    });

    test('math', () {
      var tmpl = env.fromString('{{ (1 + 1 * 2) - 3 / 2 }}|{{ 2**3 }}');
      expect(tmpl.render(), equals('1.5|8'));
    });

    test('div', () {
      var tmpl = env.fromString('{{ 3 // 2 }}|{{ 3 / 2 }}|{{ 3 % 2 }}');
      expect(tmpl.render(), equals('1|1.5|1'));
    });

    test('unary', () {
      var tmpl = env.fromString('{{ +3 }}|{{ -3 }}');
      expect(tmpl.render(), equals('3|-3'));
    });

    test('concat', () {
      var tmpl = env.fromString('{{ [1, 2] ~ "foo" }}');
      expect(tmpl.render(), equals('[1, 2]foo'));
    });

    test('compare', () {
      var tmpl = env.fromString('{{ 1 > 0 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 1 >= 1 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 < 3 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 3 <= 4 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 4 == 4 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 4 != 5 }}');
      expect(tmpl.render(), equals('true'));
    });

    test('compare parens', () {
      var tmpl = env.fromString('{{ i == (j < 5) }}');
      expect(tmpl.render({'i': 2, 'j': 3}), equals('false'));
    });

    test('compare compound', () {
      var data = {'a': 4, 'b': 2, 'c': 3};
      var tmpl = env.fromString('{{ 4 < 2 < 3 }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ a < b < c }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ 4 > 2 > 3 }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ a > b > c }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ 4 > 2 < 3 }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ a > b < c }}');
      expect(tmpl.render(data), equals('true'));
    });

    test('inop', () {
      var tmpl =
          env.fromString('{{ 1 in [1, 2, 3] }}|{{ 1 not in [1, 2, 3] }}');
      expect(tmpl.render(), equals('true|false'));
    });

    test('collection literal', () {
      var tmpl = env.fromString('{{ [] }}');
      expect(tmpl.render(), equals('[]'));
      tmpl = env.fromString('{{ {} }}');
      expect(tmpl.render(), equals('{}'));
      tmpl = env.fromString('{{ () }}');
      expect(tmpl.render(), equals('[]'));
    });

    test('numeric literal', () {
      var tmpl = env.fromString('{{ 1 }}');
      expect(tmpl.render(), equals('1'));
      tmpl = env.fromString('{{ 123 }}');
      expect(tmpl.render(), equals('123'));
      tmpl = env.fromString('{{ 12_34_56 }}');
      expect(tmpl.render(), equals('123456'));
      tmpl = env.fromString('{{ 1.2 }}');
      expect(tmpl.render(), equals('1.2'));
      tmpl = env.fromString('{{ 34.56 }}');
      expect(tmpl.render(), equals('34.56'));
      tmpl = env.fromString('{{ 3_4.5_6 }}');
      expect(tmpl.render(), equals('34.56'));
      tmpl = env.fromString('{{ 1e0 }}');
      expect(tmpl.render(), equals('1.0'));
      tmpl = env.fromString('{{ 10e1 }}');
      expect(tmpl.render(), equals('100.0'));
      tmpl = env.fromString('{{ 2.5e100 }}');
      expect(tmpl.render(), equals('2.5e+100'));
      tmpl = env.fromString('{{ 2.5e+100 }}');
      expect(tmpl.render(), equals('2.5e+100'));
      tmpl = env.fromString('{{ 25.6e-10 }}');
      expect(tmpl.render(), equals('2.56e-9'));
      tmpl = env.fromString('{{ 1_2.3_4e5_6 }}');
      expect(tmpl.render(), equals('1.234e+57'));
    });

    test('bool', () {
      var tmpl = env.fromString(
          '{{ true and false }}|{{ false or true }}|{{ not false }}');
      expect(tmpl.render(), equals('false|true|true'));
    });

    test('grouping', () {
      var tmpl = env.fromString(
          '{{ (true and false) or (false and true) and not false }}');
      expect(tmpl.render(), equals('false'));
    });

    test('django attr', () {
      var tmpl = env.fromString('{{ [1, 2, 3].0 }}');
      expect(tmpl.render(), equals('1'));
      tmpl = env.fromString('{{ [[1]].0.0 }}');
      expect(tmpl.render(), equals('1'));
    });

    test('conditional expression', () {
      var tmpl = env.fromString('{{ 0 if true else 1 }}');
      expect(tmpl.render(), equals('0'));
    });

    test('short conditional expression', () {
      var tmpl = env.fromString('<{{ 1 if false }}>');
      expect(tmpl.render(), equals('<>'));
    });

    test('filter priority', () {
      var tmpl = env.fromString('{{ "foo" | upper + "bar" | upper }}');
      expect(tmpl.render(), equals('FOOBAR'));
    });

    test('function calls', () {
      expect(() => env.fromString('{{ foo(*foo, bar) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(*foo, *bar) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(**foo, *bar) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(**foo, bar) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(**foo, **bar) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(**foo, bar=42) }}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{{ foo(foo, bar) }}'), returnsNormally);
      expect(() => env.fromString('{{ foo(foo, bar=42) }}'), returnsNormally);
      expect(() => env.fromString('{{ foo(foo, bar=23, *args) }}'),
          returnsNormally);
      expect(() => env.fromString('{{ foo(foo, *args, bar=23) }}'),
          returnsNormally);
      expect(
          () => env.fromString('{{ foo(a, b=c, *d, **e) }}'), returnsNormally);
      expect(() => env.fromString('{{ foo(*foo, bar=42) }}'), returnsNormally);
      expect(() => env.fromString('{{ foo(*foo, **bar) }}'), returnsNormally);
      expect(() => env.fromString('{{ foo(*foo, bar=42, **baz) }}'),
          returnsNormally);
      expect(() => env.fromString('{{ foo(foo, *args, bar=23, **baz) }}'),
          returnsNormally);
    });

    test('tuple expr', () {
      expect(() => env.fromString('{{ () }}'), returnsNormally);
      expect(() => env.fromString('{{ (1, 2) }}'), returnsNormally);
      expect(() => env.fromString('{{ (1, 2,) }}'), returnsNormally);
      expect(() => env.fromString('{{ 1, }}'), returnsNormally);
      expect(() => env.fromString('{{ 1, 2 }}'), returnsNormally);
      expect(() => env.fromString('{% for foo, bar in seq %}...{% endfor %}'),
          returnsNormally);
      expect(() => env.fromString('{% for x in foo, bar %}...{% endfor %}'),
          returnsNormally);
      expect(() => env.fromString('{% for x in foo, %}...{% endfor %}'),
          returnsNormally);
    });

    test('triling comma', () {
      // tuple is list
      var tmpl = env.fromString('{{ (1, 2,) }}|{{ [1, 2,] }}|{{ {1: 2,} }}');
      expect(tmpl.render(), equals('[1, 2]|[1, 2]|{1: 2}'));
    });

    test('block end name', () {
      expect(env.fromString('{% block foo %}...{% endblock foo %}'),
          isA<Template>());
      expect(() => env.fromString('{% block x %}{% endblock y %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('string concatenation', () {
      var tmpl = env.fromString('{{ "foo" "bar" "baz" }}');
      expect(tmpl.render(), equals('foobarbaz'));
    });

    test('notin', () {
      var tmpl = env.fromString('{{ not 42 in bar }}');
      expect(tmpl.render({'bar': range(100)}), equals('false'));
    });

    test('operator precedence', () {
      var tmpl = env.fromString('{{ 2 * 3 + 4 % 2 + 1 - 2 }}');
      expect(tmpl.render(), equals('5'));
    });

    test('raw2', () {
      var tmpl = env.fromString('{% raw %}{{ FOO }} and {% BAR %}{% endraw %}');
      expect(tmpl.render(), equals('{{ FOO }} and {% BAR %}'));
    });

    test('operator and', () {
      var tmpl = env.fromString(
          '<{% if page[\'next\'] and page[\'next\'].path %}ok{% endif %}>');
      expect(tmpl.render({'page': {}}), equals('<>'));
    });

    test('operator or', () {
      var tmpl = env.fromString(
          '<{% if page[\'next\'] or empty[\'test\'] %}ok{% endif %}>');
      var page = {'next': '5'};
      expect(tmpl.render({'page': page}), equals('<ok>'));
    });

    test('const', () {
      var tmpl = env.fromString('{{ true }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none }}');
      expect(tmpl.render(), equals(''));
      tmpl = env.fromString('{{ none is defined }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ missing is defined }}');
      expect(tmpl.render(), equals('false'));
    });

    test('neg filter priority', () {
      var tmpl = env.fromString('{{ -1|foo }}');

      expect(tmpl.body, predicate<Filter>((filter) {
        var expression = filter.arguments![0];
        return expression is Unary &&
            expression.operator == UnaryOperator.minus;
      }));
    });

    test('const assign', () {
      var matcher = throwsA(isA<TemplateSyntaxError>());
      expect(() => env.fromString('{% set true = 42 %}'), matcher);
      expect(
          () => env.fromString('{% for none in seq %}{% endfor %}'), matcher);
    });

    test('localset', () {
      var tmpl = env.fromString(
          '{% set foo = 0 %}{% for item in [1, 2] %}{% set foo = 1 %}'
          '{% endfor %}{{ foo }}');
      expect(tmpl.render(), equals('0'));
    });

    test('parse unary', () {
      var foo = {'bar': 42};
      var tmpl = env.fromString('{{ -foo.bar }}');
      expect(tmpl.render({'foo': foo}), equals('-42'));
      tmpl = env.fromString('{{ foo.bar }}');
      expect(tmpl.render({'foo': foo}), equals('42'));
    });
  });
}
