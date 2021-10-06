import 'dart:collection' show MapBase;
import 'dart:math' show Random;

import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class User extends MapBase<String, Object?> {
  User(this.username);

  String username;

  @override
  Iterable<String> get keys => const <String>['username'];

  @override
  String operator [](Object? key) {
    switch (key) {
      case 'username':
        return username;
      default:
        throw NoSuchMethodError.withInvocation(
            this, Invocation.getter(Symbol('$key')));
    }
  }

  @override
  void operator []=(String key, Object? value) {
    switch (key) {
      case 'username':
        username = value as String;
        break;
      default:
        throw NoSuchMethodError.withInvocation(
            this, Invocation.setter(Symbol(key), value));
    }
  }

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
  group('Filter', () {
    test('filter calling', () {
      var result = env.callFilter('sum', [[1, 2, 3]], {});
      expect(result, equals(6));
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

    // TODO: add test: dictsort
    // test('dictsort', () {});

    test('batch', () {
      var data = {'foo': range(10)};
      var tmpl = env.fromString('{{ foo|batch(3) }}');
      var result = tmpl.render(data);
      expect(result, equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]'));
      tmpl = env.fromString('{{ foo|batch(3, "X") }}');
      result = tmpl.render(data);
      expect(result, equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    test('slice', () {
      var data = {'foo': range(10)};
      var tmpl = env.fromString('{{ foo|slice(3) }}');
      var result = tmpl.render(data);
      expect(result, equals('[[0, 1, 2, 3], [4, 5, 6], [7, 8, 9]]'));
      tmpl = env.fromString('{{ foo|slice(3, "X") }}');
      result = tmpl.render(data);
      expect(result, equals('[[0, 1, 2, 3], [4, 5, 6, X], [7, 8, 9, X]]'));
    });

    test('escape', () {
      var tmpl = env.fromString('''{{ '<">&'|escape }}''');
      expect(tmpl.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('trim', () {
      var data = {'foo': '  ..stays..'};
      var tmpl = env.fromString('{{ foo|trim() }}');
      expect(tmpl.render(data), equals('..stays..'));
      tmpl = env.fromString('{{ foo|trim(".") }}');
      expect(tmpl.render(data), equals('  ..stays'));
      tmpl = env.fromString('{{ foo|trim(" .") }}');
      expect(tmpl.render(data), equals('stays'));
    });

    // add test: striptags
    // test('striptags', () {});

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
      var tmpl = env.fromString('{{ value|float(defaultValue=1.0) }}');
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
      // no bigint '12345678901234567890': '12345678901234567890'
      var tmpl = env.fromString('{{ value|int }}');
      expect(tmpl.render({'value': '42'}), equals('42'));
      expect(tmpl.render({'value': 'abc'}), equals('0'));
      expect(tmpl.render({'value': '32.32'}), equals('32'));
    });

    test('int base', () {
      var tmpl = env.fromString('{{ value|int(base=16) }}');
      expect(tmpl.render({'value': '0x4d32'}), equals('19762'));
      tmpl = env.fromString('{{ value|int(base=8) }}');
      expect(tmpl.render({'value': '011'}), equals('9'));
      tmpl = env.fromString('{{ value|int(base=16) }}');
      expect(tmpl.render({'value': '0x33Z'}), equals('0'));
    });

    test('int default', () {
      var tmpl = env.fromString('{{ value|int(defaultValue=1) }}');
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
      var tmpl = env.fromString('{{ users|join(", ", "username") }}');
      var users = [User('foo'), User('bar')];
      expect(tmpl.render({'users': users}), equals('foo, bar'));
    });

    test('last', () {
      var tmpl = env.fromString('''{{ foo|last }}''');
      expect(tmpl.render({'foo': range(10)}), equals('9'));
    });

    test('length', () {
      var tmpl = env.fromString('{{ "hello world"|length }}');
      expect(tmpl.render(), equals('11'));
    });

    test('lower', () {
      var tmpl = env.fromString('''{{ "FOO"|lower }}''');
      expect(tmpl.render(), equals('foo'));
    });

    test('pprint', () {
      var tmpl = env.fromString('{{ value|pprint }}');
      var list = <int>[for (var i = 0; i < 10; i += 1) i];
      expect(tmpl.render({'value': list}), equals(format(list)));
    });

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
      var values = [1, 2, 3, 4, 5];
      var tmpl = env.fromString('{{ values|string }}');
      expect(tmpl.render({'values': values}), equals('$values'));
    });

    // TODO: add test: truncate
    // test('truncate', () {});

    // TODO: add test: title
    // test('title', () {});

    // TODO: add test: truncate
    // test('truncate', () {});

    // TODO: add test: truncate very short
    // test('truncate very short', () {});

    // TODO: add test: truncate end length
    // htest('truncate end lengthh', () {});

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
      var tmpl =
          env.fromString('{% filter lower|escape %}<HEHE>{% endfilter %}');
      expect(tmpl.render(), equals('&lt;hehe&gt;'));
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
          '{% filter upper|replace(\'FOO\', \'foo\') %}foobar{% endfilter %}');
      expect(tmpl.render(), equals('fooBAR'));
    });

    test('replace', () {
      var env = Environment();
      var tmpl = env.fromString('{{ string|replace("o", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('<f4242>'));
      env = Environment(autoEscape: true);
      tmpl = env.fromString('{{ string|replace("o", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('&lt;f4242&gt;'));
      tmpl = env.fromString('{{ string|replace("<", "42") }}');
      expect(tmpl.render({'string': '<foo>'}), equals('42foo&gt;'));
      tmpl = env.fromString('{{ string|replace("o", ">x<") }}');
      expect(tmpl.render({'string': 'foo'}), equals('f&gt;x&lt;&gt;x&lt;'));
    });

    test('force escape', () {
      var tmpl = env.fromString('{{ x|forceescape }}');
      var x = Markup.escaped('<div />');
      expect(tmpl.render({'x': x}), equals('&lt;div /&gt;'));
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
      var result =
          tmpl.render({'string': 'Hello!\nThis is Jinja saying something.'});
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

    // TODO: add test: filter undefined in cond expr
    // test('filter undefined in cond expr', () {});
  });
}
