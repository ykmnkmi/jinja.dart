import 'dart:math' show Random;

import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class User {
  User(this.name);

  String name;
}

void main() {
  group('Filter', () {
    test('filter calling', () {
      var positional = [
        [1, 2, 3]
      ];

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
      var data = {
        'foo': {'aa': 0, 'b': 1, 'c': 2, 'AB': 3}
      };

      var tmpl = env.fromString('{{ foo|dictsort() }}');
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
      expect(tmpl.render(), equals('&lt;&#34;&gt;&amp;'));
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
      var data = {
        'foo': '  <p>just a small   \n <a href="#">'
            'example</a> link</p>\n<p>to a webpage</p> '
            '<!-- <p>and some commented stuff</p> -->'
      };

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

    // TODO: add test: format
    // test('format', () {});

    // TODO: add test: indent
    // test('indent', () {});

    // TODO: add test: indent markup input
    // test('indent markup input', () {});

    // TODO: add test: indent width string
    // test('indent width string', () {});

    test('int', () {
      var tmpl = env.fromString('{{ value|int }}');
      expect(tmpl.render({'value': '42'}), equals('42'));
      expect(tmpl.render({'value': 'abc'}), equals('0'));
      expect(tmpl.render({'value': '32.32'}), equals('0'));
    });

    test('int base', () {
      var tmpl = env.fromString('{{ value|int(0, 8) }}');
      expect(tmpl.render({'value': '11'}), equals('9'));
      tmpl = env.fromString('{{ value|int(0, 16) }}');
      expect(tmpl.render({'value': '33Z'}), equals('0'));
    });

    test('int default', () {
      var tmpl = env.fromString('{{ value|int(1) }}');
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
      var data = {
        'users': [User('foo'), User('bar')]
      };

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
      var data = {
        'values': [1, 2, 3, 4, 5]
      };

      var tmpl = env.fromString('{{ values|string }}');
      expect(tmpl.render(data), equals('${[1, 2, 3, 4, 5]}'));
    });

    // TODO: add test: title
    // test('title', () {});

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
      tmpl = env.fromString('{{ "foo bar baz"|truncate(9, true) }}');
      expect(tmpl.render(), equals('foo bar baz'));
    });

    test('truncate end lengthh', () {
      var tmpl = env.fromString('{{ "Joel is a slug"|truncate(7, true) }}');
      expect(tmpl.render(), equals('Joel...'));
    });

    test('upper', () {
      var tmpl = env.fromString('{{ "foo"|upper }}');
      expect(tmpl.render(), equals('FOO'));
    });

    // TODO: add test: urlize
    // test('urlize', () {});

    // TODO: add test: urlize rel policy
    // test('urlize rel policy', () {});

    // TODO: add test: urlize target parameter
    // test('urlize target parameter', () {});

    // TODO: add test: urlize extra schemes parameter
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

    // TODO: add test: sum
    // test('sum', () {});

    // TODO: add test: sum attributes
    // test('sum attributes', () {});

    // TODO: add test: sum attributes nested
    // test('sum attributes nested', () {});

    // TODO: add test: sum attributes tuple
    // test('sum attributes tuple', () {});

    // TODO: add test: abs
    // test('abs', () {});

    // TODO: add test: round positive
    // test('round positive', () {});

    // TODO: add test: round negative
    // test('round negative', () {});

    // TODO: add test: xmlattr
    // test('xmlattr', () {});

    // TODO: add test: sortN
    // test('sortN', () {});

    // TODO: add test: unique
    // test('unique', () {});

    // TODO: add test: unique case sensitive
    // test('unique case sensitive', () {});

    // TODO: add test: unique attribute
    // test('unique attribute', () {});

    // TODO: add test: min max
    // test('min max', () {});

    // TODO: add test: min max attribute
    // test('min max attribute', () {});

    // TODO: add test: groupby
    // test('groupby', () {});

    // TODO: add test: groupby tuple index
    // test('groupby tuple index', () {});

    // TODO: add test: groupby multidot
    // test('groupby multidot', () {});

    // TODO: add test: groupby default
    // test('groupby default', () {});

    test('filtertag', () {
      var tmpl = env.fromString(
          '{% filter upper|replace("FOO", "foo") %}foobar{% endfilter %}');
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

    test('force escape', () {
      var data = {'x': Markup.escaped('<div />')};
      var tmpl = env.fromString('{{ x|forceescape }}');
      expect(tmpl.render(data), equals('&lt;div /&gt;'));
    });

    test('safe', () {
      var env = Environment(autoEscape: true);
      var tmpl = env.fromString('{{ "<div>foo</div>"|safe }}');
      expect(tmpl.render(), equals('<div>foo</div>'));
      tmpl = env.fromString('{{ "<div>foo</div>" }}');
      expect(tmpl.render(), equals('&lt;div&gt;foo&lt;/div&gt;'));
    });

    // TODO: add test: url encode
    // test('url encode', () {});

    // TODO: add test: simple map
    // test('simple map', () {});

    // TODO: add test: map sum
    // test('map sum', () {});

    // TODO: add test: attribute map
    // test('attribute map', () {});

    // TODO: add test: empty map
    // test('empty map', () {});

    // TODO: add test: map default
    // test('map default', () {});

    // TODO: add test: simple select
    // test('simple select', () {});

    // TODO: add test: bool select
    // test('bool select', () {});

    // TODO: add test: simple reject
    // test('simple reject', () {});

    // TODO: add test: simple reject attr
    // test('simple reject attr', () {});

    // TODO: add test: func select attr
    // test('func select attr', () {});

    // TODO: add test: func reject attr
    // test('func reject attr', () {});

    // TODO: add test: json dump
    // test('json dump', () {});

    // TODO: add test: map default
    // test('map default', () {});

    test('wordwrap', () {
      var env = Environment(newLine: '\n');
      var tmpl = env.fromString('{{ string|wordwrap(20) }}');
      var data = {'string': 'Hello!\nThis is Jinja saying something.'};
      var result = tmpl.render(data);
      expect(result, equals('Hello!\nThis is Jinja saying\nsomething.'));
    });

    // TODO: add test: filter undefined
    // test('filter undefined', () {});

    // TODO: add test: filter undefined in if
    // test('filter undefined in if', () {});

    // TODO: add test: filter undefined in elif
    // test('filter undefined in elif', () {});

    // TODO: add test: filter undefined in else
    // test('filter undefined in else', () {});

    // TODO: add test: filter undefined in nested if
    // test('filter undefined in nested if', () {});

    test('filter undefined in cond expr', () {
      var t1 = env.fromString('{{ x|f if x is defined else "foo" }}');
      var t2 = env.fromString('{{ "foo" if x is not defined else x|f }}');
      expect(t1.render(), equals('foo'));
      expect(t2.render(), equals('foo'));
    });
  });
}
