import 'dart:math' show Random;

import 'package:jinja/jinja.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

import 'environment.dart';

class User {
  User(this.name);

  String? name;
}

class FullName {
  FullName(this.first, this.last);

  String? first;

  String? last;
}

class FirstName {
  FirstName(this.first);

  String? first;
}

void main() {
  group('Filter', () {
    var aNoFilterNamedF = throwsA(
      predicate<TemplateAssertionError>(
        (error) => error.message == "No filter named 'f'",
      ),
    );

    var rNoFilterNamedF = throwsA(
      predicate<TemplateRuntimeError>(
        (error) => error.message == "No filter named 'f'",
      ),
    );

    test('filter calling', () {
      var nums = [1, 2, 3];
      var positional = [nums];
      expect(env.callFilter('sum', positional), equals(6));
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
      var foo = {'aa': 0, 'AB': 3, 'b': 1, 'c': 2};
      var data = {'foo': foo};
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
      var data = {'foo': foo};
      var result = env.fromString('{{ foo|striptags }}').render(data);
      expect(result, equals('just a small example link to a webpage'));
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

    // TODO(filters): add test - format
    // test('format', () {});

    // TODO(filters): add test - indent
    // test('indent', () {});

    // TODO(filters): add test - indent markup input
    // test('indent markup input', () {});

    // TODO(filters): add test - indent width string
    // test('indent width string', () {});

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

      var env2 = Environment(autoEscape: true);
      tmpl = env2.fromString('{{ ["<foo>", "<span>foo</span>"|safe]|join }}');
      expect(tmpl.render(), equals('&lt;foo&gt;<span>foo</span>'));
    });

    test('join attribute', () {
      var list = [User('foo'), User('bar')];
      var data = {'users': list};
      var tmpl = env.fromString('{{ users|map(attribute="name")|join(", ") }}');
      expect(tmpl.render(data), equals('foo, bar'));
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

    // TODO(filters): add test - items
    // test('items', () {});

    // TODO(filters): add test - items unefined
    // test('items unefined', () {});

    // TODO(filters): add test - pprint
    // test('pprint', () {});

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

    // TODO(filters): add test - title
    // test('title', () {});

    test('truncate', () {
      var data = {'data': 'foobar baz bar' * 10, 'smalldata': 'foobar baz bar'};

      var tmpl = env.fromString(
        '{{ data|truncate(length=15, killWords=true, end=">>>") }}',
      );

      expect(tmpl.render(data), equals('foobar baz b>>>'));
      tmpl = env.fromString('{{ data|truncate(length=15, end=">>>") }}');
      expect(tmpl.render(data), equals('foobar baz>>>'));
      tmpl = env.fromString('{{ smalldata|truncate(length=15) }}');
      expect(tmpl.render(data), equals('foobar baz bar'));
    });

    test('truncate very short', () {
      var tmpl = env.fromString('{{ "foo bar baz"|truncate(length=9) }}');
      expect(tmpl.render(), equals('foo bar baz'));

      tmpl = env.fromString(
        '{{ "foo bar"|truncate(length=6, killWords=true) }}',
      );

      expect(tmpl.render(), equals('foo bar'));
    });

    test('truncate end length', () {
      var tmpl = env.fromString(
        '{{ "Joel is a slug"|truncate(length=7, killWords=true) }}',
      );

      expect(tmpl.render(), equals('Joel...'));
    });

    test('upper', () {
      var tmpl = env.fromString('{{ "foo"|upper }}');
      expect(tmpl.render(), equals('FOO'));
    });

    // TODO(filters): add test - urlize
    // test('urlize', () {});

    // TODO(filters): add test - urlize rel policy
    // test('urlize rel policy', () {});

    // TODO(filters): add test - urlize target parameter
    // test('urlize target parameter', () {});

    // TODO(filters): add test - urlize extra schemes parameter
    // test('urlize extra schemes parameter', () {});

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

      var values = [
        {'value': 23},
        {'value': 1},
        {'value': 18},
      ];

      expect(tmpl.render({'values': values}), equals('42'));
    });

    test('sum attributes nested', () {
      var tmpl = env.fromString('{{ values|map(item="real.value")|sum }}');

      var values = [
        {
          'real': {'value': 23}
        },
        {
          'real': {'value': 1}
        },
        {
          'real': {'value': 18}
        },
      ];

      expect(tmpl.render({'values': values}), equals('42'));
    }, skip: 'Nested attributes and items not supported.');

    test('sum attributes tuple', () {
      var tmpl = env.fromString('{{ values.entries|map("list")|map(item=1)|sum }}');
      var values = {'foo': 23, 'bar': 1, 'baz': 18};
      expect(tmpl.render({'values': values}), equals('42'));
    });

    test('abs', () {
      var tmpl = env.fromString('{{ -1|abs }}|{{ 1|abs }}');
      expect(tmpl.render(), equals('1|1'));
    });

    // TODO(filters): add test - round positive
    // test('round positive', () {});

    // TODO(filters): add test - round negative
    // test('round negative', () {});

    // TODO(filters): add test - xmlattr
    // test('xmlattr', () {});

    // TODO(filters): add test - sortN
    // test('sortN', () {});

    // TODO(filters): add test - unique
    // test('unique', () {});

    // TODO(filters): add test - unique case sensitive
    // test('unique case sensitive', () {});

    // TODO(filters): add test - unique attribute
    // test('unique attribute', () {});

    // TODO(filters): add test - min max
    // test('min max', () {});

    // TODO(filters): add test - min max attribute
    // test('min max attribute', () {});

    // TODO(filters): add test - groupby
    // test('groupby', () {});

    // TODO(filters): add test - groupby tuple index
    // test('groupby tuple index', () {});

    // TODO(filters): add test - groupby multidot
    // test('groupby multidot', () {});

    // TODO(filters): add test - groupby default
    // test('groupby default', () {});

    // TODO(filters): add test - groupby case
    // test('groupby case', () {});

    test('filtertag', () {
      var tmpl = env.fromString(
        '{% filter upper|replace("FOO", "foo") %}foobar{% endfilter %}',
      );

      expect(tmpl.render(), equals('fooBAR'));
    });

    test('replace', () {
      var tmpl = env.fromString('{{ string|replace("o", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('<f4242>'));

      var env2 = Environment(autoEscape: true);
      tmpl = env2.fromString('{{ string|replace("o", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('&lt;f4242&gt;'));
      tmpl = env2.fromString('{{ string|replace("<", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('42foo&gt;'));
      tmpl = env2.fromString('{{ string|replace("o", ">x<") }}');
      expect(tmpl.render({'string': 'foo'}), equals('f&gt;x&lt;&gt;x&lt;'));
    });

    test('forceescape', () {
      var tmpl = env.fromString('{{ x|forceescape }}');
      var div = Markup.escaped('<div />');
      expect(tmpl.render({'x': div}), equals('&lt;div /&gt;'));
    });

    test('safe', () {
      var env = Environment(autoEscape: true);
      var tmpl = env.fromString('{{ "<div>foo</div>"|safe }}');
      expect(tmpl.render(), equals('<div>foo</div>'));
      tmpl = env.fromString('{{ "<div>foo</div>" }}');
      expect(tmpl.render(), equals('&lt;div&gt;foo&lt;/div&gt;'));
    });

    // TODO(filters): add test - urlencode
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

    // TODO(filters): add test - simple select
    // test('simple select', () {});

    // TODO(filters): add test - bool select
    // test('bool select', () {});

    // TODO(filters): add test - simple reject
    // test('simple reject', () {});

    // TODO(filters): add test - bool reject
    // test('bool reject', () {});

    // TODO(filters): add test - simple select attr
    // test('simple select attr', () {});

    // TODO(filters): add test - simple reject attr
    // test('simple reject attr', () {});

    // TODO(filters): add test - func select attr
    // test('func select attr', () {});

    // TODO(filters): add test - func reject attr
    // test('func reject attr', () {});

    test('json dump', () {
      var env = Environment(autoEscape: true);
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
    }, skip: 'Assertion checks not yet implemented.');

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
