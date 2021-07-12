import 'dart:math' show Random;

import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class User {
  User(this.name);

  final String name;
}

class IntIsh {
  int toInt() {
    return 42;
  }
}

void main() {
  group('Filter', () {
    test('filter calling', () {
      expect(environment.callFilter('sum', [1, 2, 3]), equals(6));
    });

    test('capitalize', () {
      expect(parse('{{ "foo bar" | capitalize }}').render(), equals('Foo bar'));
    });

    test('center', () {
      expect(render('{{ "foo" | center(9) }}'), equals('   foo   '));
    });

    test('default', () {
      expect(render('{{ missing | default("no") }}'), equals('no'));
      expect(render('{{ false | default("no") }}'), equals('false'));
      expect(render('{{ false | default("no", true) }}'), equals('no'));
      expect(render('{{ given | default("no") }}', {'given': 'yes'}),
          equals('yes'));
    });

    test('dictsort', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('batch', () {
      expect(
          render(
              '{{ foo | batch(3) | list }}|'
              '{{ foo | batch(3, "X") | list }}',
              {'foo': range(10)}),
          equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|'
              '[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    test('slice', () {
      throw UnimplementedError('slice');
    }, skip: true);

    test('escape', () {
      expect(render('''{{ '<">&'|escape }}'''), equals('&lt;&#34;&gt;&amp;'));
    });

    test('trim', () {
      throw UnimplementedError('trim');
    }, skip: true);

    test('striptags', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('filesizeformat', () {
      expect(render('{{ 100 | filesizeformat }}'), equals('100 Bytes'));
      expect(render('{{ 1000 | filesizeformat }}'), equals('1.0 kB'));
      expect(render('{{ 1000000 | filesizeformat }}'), equals('1.0 MB'));
      expect(render('{{ 1000000000 | filesizeformat }}'), equals('1.0 GB'));
      expect(render('{{ 1000000000000 | filesizeformat }}'), equals('1.0 TB'));
      expect(render('{{ 100 | filesizeformat(true) }}'), equals('100 Bytes'));
      expect(render('{{ 1000 | filesizeformat(true) }}'), equals('1000 Bytes'));
      expect(
          render('{{ 1000000 | filesizeformat(true) }}'), equals('976.6 KiB'));
      expect(render('{{ 1000000000 | filesizeformat(true) }}'),
          equals('953.7 MiB'));
      expect(render('{{ 1000000000000 | filesizeformat(true) }}'),
          equals('931.3 GiB'));
    });

    test('first', () {
      expect(render('{{ foo | first }}', {'foo': range(10)}), equals('0'));
    });

    test('float', () {
      final template = parse('{{ value | float }}');
      expect(template.render({'value': '42'}), equals('42.0'));
      expect(template.render({'value': 'abc'}), equals('0.0'));
      expect(template.render({'value': '32.32'}), equals('32.32'));
    });

    test('float default', () {
      expect(render('{{ value | float(default=1.0) }}', {'value': 'abc'}),
          equals('1.0'));
    });

    test('format', () {
      throw UnimplementedError('format');
    }, skip: true);

    test('indent', () {
      throw UnimplementedError('indent');
    }, skip: true);

    test('indent markup input', () {
      throw UnimplementedError('test indent markup input not added');
    }, skip: true);

    test('int', () {
      // no bigint '12345678901234567890': '12345678901234567890'
      final template = parse('{{ value | int }}');
      expect(template.render({'value': '42'}), equals('42'));
      expect(template.render({'value': 'abc'}), equals('0'));
      expect(template.render({'value': '32.32'}), equals('32'));
    });

    test('int base', () {
      expect(render('{{ value | int(base=16) }}', {'value': '0x4d32'}),
          equals('19762'));
      expect(
          render('{{ value | int(base=8) }}', {'value': '011'}), equals('9'));
      expect(render('{{ value | int(base=16) }}', {'value': '0x33Z'}),
          equals('0'));
    });

    test('int default', () {
      expect(render('{{ value | int(default=1) }}', {'value': 'abc'}),
          equals('1'));
    });

    test('int special method', () {
      expect(render('{{ value | int }}', {'value': IntIsh()}), equals('42'));
    });

    test('join', () {
      expect(render('{{ [1, 2, 3] | join("|") }}'), equals('1|2|3'));
      expect(
          Environment(autoEscape: true)
              .fromString('{{ ["<foo>", "<span>foo</span>" | safe] | join }}')
              .render(),
          equals('&lt;foo&gt;<span>foo</span>'));
    });

    test('join attribute', () {
      expect(
          render('{{ users | join(", ", "username") }}', {
            'users': [
              {'username': 'foo'},
              {'username': 'bar'},
            ]
          }),
          equals('foo, bar'));
    });

    test('last', () {
      expect(render('''{{ foo | last }}''', {'foo': range(10)}), equals('9'));
    });

    test('length', () {
      expect(render('{{ "hello world" | length }}'), equals('11'));
    });

    test('lower', () {
      expect(render('''{{ "FOO" | lower }}'''), equals('foo'));
    });

    test('pprint', () {
      final list = <int>[for (var i = 0; i < 10; i += 1) i];
      expect(render('{{ value | pprint }}', {'value': list}),
          equals(format(list)));
    });

    test('random', () {
      final numbers = '1234567890';
      final template = Environment(random: Random(0))
          .fromString('{{ "$numbers" | random }}');
      final random = Random(0);

      for (var i = 0; i < 10; i += 1) {
        expect(template.render(), equals(numbers[random.nextInt(10)]));
      }
    });

    test('reverse', () {
      expect(
          render('{{ "foobar" | reverse | join }}|'
              '{{ [1, 2, 3] | reverse | list }}'),
          equals('raboof|[3, 2, 1]'));
    });

    test('string', () {
      final values = [1, 2, 3, 4, 5];
      expect(render('{{ values | string }}', {'values': values}),
          equals('$values'));
    });

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('title', () {
      throw UnimplementedError('title');
    }, skip: true);

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('truncate very short', () {
      throw UnimplementedError('truncate very short');
    }, skip: true);

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('truncate end length', () {
      throw UnimplementedError('truncate end length');
    }, skip: true);

    test('upper', () {
      expect(render('{{ "foo" | upper }}'), equals('FOO'));
    });

    test('urlize', () {
      throw UnimplementedError('urlize');
    }, skip: true);

    test('urlize rel policy', () {
      throw UnimplementedError('urlize rel policy');
    }, skip: true);

    test('urlize target parameter', () {
      throw UnimplementedError('urlize target parameter');
    }, skip: true);

    test('wordcount', () {
      expect(render('{{ "foo bar baz" | wordcount }}'), equals('3'));
    });

    test('block', () {
      throw UnimplementedError('block');
    }, skip: true);

    test('chaining', () {
      expect(render('{{ ["<foo>", "<bar>"]| first | upper | escape }}'),
          equals('&lt;FOO&gt;'));
    });

    test('force escape', () {
      expect(render('{{ x | forceescape }}', {'x': Markup.escaped('<div />')}),
          equals('&lt;div /&gt;'));
    });

    test('safe', () {
      final environment = Environment(autoEscape: true);
      expect(environment.fromString('{{ "<div>foo</div>" | safe }}').render(),
          equals('<div>foo</div>'));
      expect(environment.fromString('{{ "<div>foo</div>" }}').render(),
          equals('&lt;div&gt;foo&lt;/div&gt;'));
    });

    test('wordwrap', () {
      expect(
          Environment(newLine: '\n')
              .fromString('{{ string | wordwrap(20) }}')
              .render({'string': 'Hello!\nThis is Jinja saying something.'}),
          equals('Hello!\nThis is Jinja saying\nsomething.'));
    });
  });
}
