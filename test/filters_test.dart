import 'dart:math' show Random;

import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

import 'environment.dart';

class FirstName {
  FirstName(this.first);

  String? first;
}

class FullName {
  FullName(this.first, this.last);

  String? first;

  String? last;
}

class User {
  User(this.name);

  String? name;
}

bool noFilterNamedF(TemplateError error) {
  return error.message == "No filter named 'f'.";
}

void main() {
  group('Filter', () {
    var aNoFilterNamedF = throwsA(
      predicate<TemplateAssertionError>(noFilterNamedF),
    );

    var rNoFilterNamedF = throwsA(
      predicate<TemplateRuntimeError>(noFilterNamedF),
    );

    test('filter calling', () {
      expect(
          env.callFilter('sum', [
            [1, 2, 3]
          ]),
          equals(6));
    });

    test('capitalize', () {
      var tmpl = env.fromString('{{ "foo bar"|capitalize }}');
      expect(tmpl.render(), equals('Foo bar'));
    });

    test('center', () {
      var tmpl = env.fromString('{{ "foo"|center(9) }}');
      expect(tmpl.render(), equals('   foo   '));
    });

    test('default', () {
      var tmpl = env.fromString('{{ missing|default("no") }}');
      expect(tmpl.render(), equals('no'));
      tmpl = env.fromString('{{ false|default("no") }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false|default("no", true) }}');
      expect(tmpl.render(), equals('no'));
      tmpl = env.fromString('{{ given|default("no") }}');
      expect(tmpl.render({'given': 'yes'}), equals('yes'));
    });

    test('dictsort', () {
      var data = {
        'foo': {'aa': 0, 'AB': 3, 'b': 1, 'c': 2}
      };
      var tmpl = env.fromString('{{ foo|dictsort }}');
      expect(tmpl.render(data), equals('[[aa, 0], [AB, 3], [b, 1], [c, 2]]'));
      tmpl = env.fromString('{{ foo|dictsort(caseSensetive=true) }}');
      expect(tmpl.render(data), equals('[[AB, 3], [aa, 0], [b, 1], [c, 2]]'));
      tmpl = env.fromString('{{ foo|dictsort(reverse=true) }}');
      expect(tmpl.render(data), equals('[[c, 2], [b, 1], [AB, 3], [aa, 0]]'));
    });

    test('batch', () {
      var data = {'foo': range(7)};
      var tmpl = env.fromString('{{ foo|batch(3) }}');
      expect(tmpl.render(data), equals('[[0, 1, 2], [3, 4, 5], [6]]'));
      tmpl = env.fromString('{{ foo|batch(3, "X") }}');
      expect(tmpl.render(data), equals('[[0, 1, 2], [3, 4, 5], [6, X, X]]'));
    });

    test('slice', () {
      var data = {'foo': range(7)};
      var tmpl = env.fromString('{{ foo|slice(3) }}');
      expect(tmpl.render(data), equals('[[0, 1, 2], [3, 4], [5, 6]]'));
      tmpl = env.fromString('{{ foo|slice(3, "X") }}');
      expect(tmpl.render(data), equals('[[0, 1, 2], [3, 4, X], [5, 6, X]]'));
    });

    test('escape', () {
      var tmpl = env.fromString('''{{ '<">&'|escape }}''');
      expect(tmpl.render(), equals('&lt;&quot;&gt;&amp;'));
    });

    test('trim', () {
      var data = {'foo': '  ..stays..'};
      var tmpl = env.fromString('{{ foo|trim }}');
      expect(tmpl.render(data), equals('..stays..'));
      tmpl = env.fromString('{{ foo|trim(".") }}');
      expect(tmpl.render(data), equals('  ..stays'));
      tmpl = env.fromString('{{ foo|trim(" .") }}');
      expect(tmpl.render(data), equals('stays'));
    });

    test('striptags', () {
      var foo = '  <p>just a small   \n <a href="#">'
          'example</a> link</p>\n<p>to a webpage</p> '
          '<!-- <p>and some commented stuff</p> -->';
      var tmpl = env.fromString('{{ foo|striptags }}');
      expect(tmpl.render({'foo': foo}),
          equals('just a small example link to a webpage'));
    });

    test('filesizeformat', () {
      var tmpl = env.fromString('{{ 100|filesizeformat }}');
      expect(tmpl.render(), equals('100 Bytes'));
      tmpl = env.fromString('{{ 1000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 kB'));
      tmpl = env.fromString('{{ 1000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 MB'));
      tmpl = env.fromString('{{ 1000000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 GB'));
      tmpl = env.fromString('{{ 1000000000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 TB'));
      tmpl = env.fromString('{{ 100|filesizeformat(true) }}');
      expect(tmpl.render(), equals('100 Bytes'));
      tmpl = env.fromString('{{ 1000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('1000 Bytes'));
      tmpl = env.fromString('{{ 1000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('976.6 KiB'));
      tmpl = env.fromString('{{ 1000000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('953.7 MiB'));
      tmpl = env.fromString('{{ 1000000000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('931.3 GiB'));
    });

    test('filesizeformat issue', () {
      var tmpl = env.fromString('{{ 300|filesizeformat }}');
      expect(tmpl.render(), equals('300 Bytes'));
      tmpl = env.fromString('{{ 3000|filesizeformat }}');
      expect(tmpl.render(), equals('3.0 kB'));
      tmpl = env.fromString('{{ 3000000|filesizeformat }}');
      expect(tmpl.render(), equals('3.0 MB'));
      tmpl = env.fromString('{{ 3000000000|filesizeformat }}');
      expect(tmpl.render(), equals('3.0 GB'));
      tmpl = env.fromString('{{ 3000000000000|filesizeformat }}');
      expect(tmpl.render(), equals('3.0 TB'));
      tmpl = env.fromString('{{ 300|filesizeformat(true) }}');
      expect(tmpl.render(), equals('300 Bytes'));
      tmpl = env.fromString('{{ 3000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('2.9 KiB'));
      tmpl = env.fromString('{{ 3000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('2.9 MiB'));
    });

    test('first', () {
      var tmpl = env.fromString('{{ foo|first }}');
      expect(tmpl.render({'foo': range(10)}), equals('0'));
    });

    test('float', () {
      var tmpl = env.fromString('{{ value|float }}');
      expect(tmpl.render({'value': '42'}), equals('42.0'));
      expect(tmpl.render({'value': 'abc'}), equals('0.0'));
      expect(tmpl.render({'value': '32.32'}), equals('32.32'));
    });

    test('float default', () {
      var tmpl = env.fromString('{{ value|float(1.0) }}');
      expect(tmpl.render({'value': 'abc'}), equals('1.0'));
    });

    // TODO(filters): add format test
    // TODO(filters): add indent test
    // TODO(filters): add indent markup input test
    // TODO(filters): add indent width string test

    test('int', () {
      var tmpl = env.fromString('{{ value|int }}');
      expect(tmpl.render({'value': '42'}), equals('42'));
      expect(tmpl.render({'value': 'abc'}), equals('0'));
      expect(tmpl.render({'value': '32.32'}), equals('0'));
    });

    test('int base', () {
      var tmpl = env.fromString('{{ value|int(base=8) }}');
      expect(tmpl.render({'value': '11'}), equals('9'));
      tmpl = env.fromString('{{ value|int(base=16) }}');
      expect(tmpl.render({'value': '33Z'}), equals('0'));
    });

    test('int default', () {
      var tmpl = env.fromString('{{ value|int(default=1) }}');
      expect(tmpl.render({'value': 'abc'}), equals('1'));
    });

    test('join', () {
      var tmpl = env.fromString('{{ [1, 2, 3]|join("|") }}');
      expect(tmpl.render(), equals('1|2|3'));
    });

    test('join attribute', () {
      var tmpl = env.fromString('{{ users|map(attribute="name")|join(", ") }}');
      expect(
          tmpl.render({
            'users': [User('foo'), User('bar')]
          }),
          equals('foo, bar'));
    });

    test('last', () {
      var tmpl = env.fromString('{{ foo|last }}');
      expect(tmpl.render({'foo': range(10)}), equals('9'));
    });

    test('length', () {
      var tmpl = env.fromString('{{ "hello world"|length }}');
      expect(tmpl.render(), equals('11'));
    });

    test('lower', () {
      var tmpl = env.fromString('{{ "FOO"|lower }}');
      expect(tmpl.render(), equals('foo'));
    });

    test('items', () {
      var d = 'abc'.split('').asMap();
      var tmpl = env.fromString('{{ d|items|list }}');
      expect(tmpl.render({'d': d}), equals('[[0, a], [1, b], [2, c]]'));
    });

    test('items undefined', () {
      var tmpl = env.fromString('{{ d|items|list }}');
      expect(tmpl.render(), equals('[]'));
    });

    // TODO(filters): add pprint test

    test('random', () {
      var expected = '1234567890';
      var random = Random(0);
      var env = Environment(random: Random(0));
      var tmpl = env.fromString('{{ "$expected"|random }}');

      for (var i = 0; i < 10; i += 1) {
        expect(tmpl.render(), equals(expected[random.nextInt(10)]));
      }
    });

    test('reverse', () {
      var tmpl = env.fromString('{{ "foobar"|reverse|join }}');
      expect(tmpl.render(), equals('raboof'));
      tmpl = env.fromString('{{ [1, 2, 3]|reverse|list }}');
      expect(tmpl.render(), equals('[3, 2, 1]'));
    });

    test('string', () {
      var list = [1, 2, 3, 4, 5];
      var data = {'values': list};
      var tmpl = env.fromString('{{ values|string }}');
      expect(tmpl.render(data), equals('${[1, 2, 3, 4, 5]}'));
    });

    test('title', () {
      var tmpl = env.fromString('{{ "foo bar"|title }}');
      expect(tmpl.render(), equals('Foo Bar'));
      tmpl = env.fromString('''{{ "foo's bar"|title }}''');
      expect(tmpl.render(), equals("Foo's Bar"));
      tmpl = env.fromString('{{ "foo   bar"|title }}');
      expect(tmpl.render(), equals('Foo   Bar'));
      tmpl = env.fromString('{{ "f bar f"|title }}');
      expect(tmpl.render(), equals('F Bar F'));
      tmpl = env.fromString('{{ "foo-bar"|title }}');
      expect(tmpl.render(), equals('Foo-Bar'));
      tmpl = env.fromString('{{ "foo\tbar"|title }}');
      expect(tmpl.render(), equals('Foo\tBar'));
      tmpl = env.fromString('{{ "FOO\tBAR"|title }}');
      expect(tmpl.render(), equals('Foo\tBar'));
      tmpl = env.fromString('{{ "foo (bar)"|title }}');
      expect(tmpl.render(), equals('Foo (Bar)'));
      tmpl = env.fromString('{{ "foo {bar}"|title }}');
      expect(tmpl.render(), equals('Foo {Bar}'));
      tmpl = env.fromString('{{ "foo [bar]"|title }}');
      expect(tmpl.render(), equals('Foo [Bar]'));
      tmpl = env.fromString('''{{ "foo <bar>"|title }}''');
      expect(tmpl.render(), equals('Foo <Bar>'));
    });

    test('truncate', () {
      var data = {'data': 'foobar baz bar' * 10, 'smalldata': 'foobar baz bar'};
      var tmpl = env.fromString('{{ data|truncate(15, true, ">>>") }}');
      expect(tmpl.render(data), equals('foobar baz b>>>'));
      tmpl = env.fromString('{{ data|truncate(15, false, ">>>") }}');
      expect(tmpl.render(data), equals('foobar baz>>>'));
      tmpl = env.fromString('{{ smalldata|truncate(15) }}');
      expect(tmpl.render(data), equals('foobar baz bar'));
    });

    test('truncate very short', () {
      var tmpl = env.fromString('{{ "foo bar baz"|truncate(9) }}');
      expect(tmpl.render(), equals('foo bar baz'));

      tmpl = env.fromString('{{ "foo bar"|truncate(6, true) }}');
      expect(tmpl.render(), equals('foo bar'));
    });

    test('truncate end length', () {
      var tmpl = env.fromString('{{ "Joel is a slug"|truncate(7, true) }}');
      expect(tmpl.render(), equals('Joel...'));
    });

    test('upper', () {
      var tmpl = env.fromString('{{ "foo"|upper }}');
      expect(tmpl.render(), equals('FOO'));
    });

    // TODO(filters): add urlize test
    // TODO(filters): add urlize rel policy test
    // TODO(filters): add urlize target parameter test
    // TODO(filters): add urlize extra schemes parameter test

    test('wordcount', () {
      var tmpl = env.fromString('{{ "foo bar baz"|wordcount }}');
      expect(tmpl.render(), equals('3'));
    });

    test('block', () {
      var tmpl = env.fromString('{% filter lower|escape %}<HE>{% endfilter %}');
      expect(tmpl.render(), equals('&lt;he&gt;'));
    });

    test('chaining', () {
      var tmpl = env.fromString('{{ ["<foo>", "<bar>"]|first|upper|escape }}');
      expect(tmpl.render(), equals('&lt;FOO&gt;'));
    });

    test('sum', () {
      var tmpl = env.fromString('{{ [1, 2, 3, 4, 5, 6]|sum }}');
      expect(tmpl.render(), equals('21'));
    });

    test('sum attributes', () {
      var tmpl = env.fromString('{{ values|map(item="value")|sum }}');
      expect(
          tmpl.render({
            'values': [
              {'value': 23},
              {'value': 1},
              {'value': 18},
            ]
          }),
          equals('42'));
    });

    test('sum attributes nested', () {
      var tmpl = env.fromString('{{ values|map(attribute="real.value")|sum }}');
      expect(
          tmpl.render({
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

    test('sum attributes tuple', () {
      var tmpl =
          env.fromString('{{ values.entries|map("list")|map(item=1)|sum }}');
      expect(
          tmpl.render({
            'values': {'foo': 23, 'bar': 1, 'baz': 18}
          }),
          equals('42'));
    });

    test('abs', () {
      var tmpl = env.fromString('{{ -1|abs }}|{{ 1|abs }}');
      expect(tmpl.render(), equals('1|1'));
    });

    // TODO(filters): add round positive test
    // TODO(filters): add round negative test
    // TODO(filters): add xmlattr test
    // TODO(filters): add sort1 test
    // TODO(filters): add sort2 test
    // TODO(filters): add sort3 test
    // TODO(filters): add sort4 test
    // TODO(filters): add sort5 test
    // TODO(filters): add sort6 test
    // TODO(filters): add sort7 test
    // TODO(filters): add sort8 test
    // TODO(filters): add unique test
    // TODO(filters): add unique case sensitive test
    // TODO(filters): add unique attribute test
    // TODO(filters): add min max test
    // TODO(filters): add min max attribute test
    // TODO(filters): add groupby test
    // TODO(filters): add groupby tuple index test
    // TODO(filters): add groupby multidot test
    // TODO(filters): add groupby default test
    // TODO(filters): add groupby case test

    test('filtertag', () {
      var tmpl = env.fromString(
          '{% filter upper|replace("FOO", "foo") %}foobar{% endfilter %}');
      expect(tmpl.render(), equals('fooBAR'));
    });

    test('replace', () {
      var tmpl = env.fromString('{{ string|replace("o", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('<f4242>'));
    });

    test('forceescape', () {}, skip: 'unsupported');

    test('safe', () {}, skip: 'unsupported');

    // TODO(filters): add urlencode test
    // test('urlencode', () {});

    test('simple map', () {
      var tmpl = env.fromString('{{ ["1", "2", "3"]|map("int")|sum }}');
      expect(tmpl.render(), equals('6'));
    });

    test('map sum', () {
      var tmpl = env.fromString('{{ [[1,2], [3], [4,5,6]]|map("sum")|list }}');
      expect(tmpl.render(), equals('[3, 3, 15]'));
    });

    test('attribute map', () {
      var tmpl = env.fromString('{{ users|map(attribute="name")|join("|") }}');
      var users = [User('john'), User('jane'), User('mike')];
      expect(tmpl.render({'users': users}), equals('john|jane|mike'));
    });

    test('empty map', () {
      var tmpl = env.fromString('{{ none|map("upper")|list }}');
      expect(tmpl.render(), equals('[]'));
    });

    test('map attribute default', () {
      var users = [
        FullName('john', 'lennon'),
        FullName('jon', null),
        FirstName('mike'),
      ];
      var data = {'users': users};

      var tmpl = env.fromString(
        '{{ users|map(attribute="last", default="smith")|join(", ") }}',
      );

      expect(tmpl.render(data), equals('lennon, smith, smith'));

      tmpl = env.fromString(
        '{{ users|map(attribute="last", default="")|join(", ") }}',
      );

      expect(tmpl.render(data), equals('lennon, , '));
    });

    test('map item default', () {
      var users = [
        {'first': 'john', 'last': 'lennon'},
        {'first': 'jon', 'last': null},
        {'first': 'mike'},
      ];

      var data = {'users': users};

      var tmpl = env.fromString(
        '{{ users|map(item="last", default="smith")|join(", ") }}',
      );

      expect(tmpl.render(data), equals('lennon, smith, smith'));

      tmpl = env.fromString(
        '{{ users|map(item="last", default="")|join(", ") }}',
      );

      expect(tmpl.render(data), equals('lennon, , '));
    });

    // TODO(filters): add simple select test
    // test('simple select', () {});

    // TODO(filters): add bool select test
    // test('bool select', () {});

    // TODO(filters): add simple reject test
    // test('simple reject', () {});

    // TODO(filters): add bool reject test
    // test('bool reject', () {});

    // TODO(filters): add simple select attr test
    // test('simple select attr', () {});

    // TODO(filters): add simple reject attr test
    // test('simple reject attr', () {});

    // TODO(filters): add func select attr test
    // test('func select attr', () {});

    // TODO(filters): add func reject attr test
    // test('func reject attr', () {});

    test('json dump', () {
      var tmpl = env.fromString('{{ x|tojson }}');
      var x = {'foo': 'bar'};
      expect(tmpl.render({'x': x}), equals('{"foo":"bar"}'));
      expect(tmpl.render({'x': '"' "ba&r'"}), equals('"\\"ba\\u0026r\\u0027"'));
      expect(tmpl.render({'x': '<bar>'}), equals('"\\u003cbar\\u003e"'));
    });

    test('wordwrap', () {
      var env = Environment(newLine: '\n');
      var tmpl = env.fromString('{{ string|wordwrap(20) }}');
      var data = {'string': 'Hello!\nThis is Jinja saying something.'};
      var result = tmpl.render(data);
      expect(result, equals('Hello!\nThis is Jinja saying\nsomething.'));
    });

    // TODO(compiler): enable test
    test('filter undefined', () {
      expect(() => env.fromString('{{ var|f }}'), aNoFilterNamedF);
    }, skip: true);

    test('filter undefined in if', () {
      var t1 = env.fromString(
        '{%- if x is defined -%}{{ x|f }}{%- else -%}x{% endif %}',
      );

      expect(t1.render(), equals('x'));
      expect(() => t1.render({'x': 42}), rNoFilterNamedF);
    });

    test('filter undefined in elif', () {
      var t1 = env.fromString(
        '{%- if x is defined -%}{{ x }}{%- elif y is defined -%}'
        '{{ y|f }}{%- else -%}foo{%- endif -%}',
      );

      expect(t1.render(), equals('foo'));
      expect(() => t1.render({'y': 42}), rNoFilterNamedF);
    });

    test('filter undefined in else', () {
      var t1 = env.fromString(
        '{%- if x is not defined -%}foo{%- else -%}{{ x|f }}{%- endif -%}',
      );

      expect(t1.render(), equals('foo'));
      expect(() => t1.render({'x': 42}), rNoFilterNamedF);
    });

    test('filter undefined in nested if', () {
      var t1 = env.fromString(
        '{%- if x is not defined -%}foo{%- else -%}{%- if y '
        'is defined -%}{{ y|f }}{%- endif -%}{{ x }}{%- endif -%}',
      );

      expect(t1.render(), equals('foo'));
      expect(t1.render({'x': 42}), equals('42'));
      expect(() => t1.render({'x': 42, 'y': 42}), rNoFilterNamedF);
    });

    test('filter undefined in cond expr', () {
      var t1 = env.fromString('{{ x|f if x is defined else "foo" }}');
      var t2 = env.fromString('{{ "foo" if x is not defined else x|f }}');
      expect(t1.render(), equals('foo'));
      expect(t2.render(), equals('foo'));

      expect(() => t1.render({'x': 42}), rNoFilterNamedF);
      expect(() => t2.render({'x': 42}), rNoFilterNamedF);
    });
  });
}
