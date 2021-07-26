import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

class User {
  User(this.name);

  final String name;
}

void main() {
  group('filter', () {
    final env = Environment();

    test('attr', () {
      final env = Environment(fieldGetter: fieldGetter);
      final template = env.fromString('{{ user | attr("name") }}');
      final user = User('jane');
      expect(template.render(user: user), equals('jane'));
    });

    test('batch', () {
      final template = env.fromString(
          "{{ foo | batch(3) | list }}|{{ foo | batch(3, 'X') | list }}");
      expect(
          template.render(foo: range(10).toList()),
          equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|'
              "[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]"));
    });

    test('capitalize', () {
      final template = env.fromString('{{ "foo bar" | capitalize }}');
      expect(template.renderMap(), equals('Foo bar'));
    });

    test('center', () {
      final template = env.fromString('{{ "foo" | center(9) }}');
      expect(template.renderMap(), equals('   foo   '));
    });

    test('chaining', () {
      final template = env
          .fromString('''{{ ['<foo>', '<bar>']| first | upper | escape }}''');
      expect(template.renderMap(), equals('&lt;FOO&gt;'));
    });

    test('default', () {
      final template = env.fromString(
          "{{ missing | default('no') }}|{{ false | default('no') }}|"
          "{{ false | default('no', true) }}|{{ given | default('no') }}");
      expect(template.renderMap(<String, Object>{'given': 'yes'}),
          equals('no|false|no|yes'));
    });

    test('escape', () {
      final template = env.fromString('''{{ '<">&' | escape }}''');
      expect(template.renderMap(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('filesizeformat', () {
      final template = env.fromString('{{ 100 | filesizeformat }}|'
          '{{ 1000 | filesizeformat }}|'
          '{{ 1000000 | filesizeformat }}|'
          '{{ 1000000000 | filesizeformat }}|'
          '{{ 1000000000000 | filesizeformat }}|'
          '{{ 100 | filesizeformat(true) }}|'
          '{{ 1000 | filesizeformat(true) }}|'
          '{{ 1000000 | filesizeformat(true) }}|'
          '{{ 1000000000 | filesizeformat(true) }}|'
          '{{ 1000000000000 | filesizeformat(true) }}');
      expect(
          template.renderMap(),
          equals('100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|'
              '1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB'));
    });

    test('first', () {
      final template = env.fromString('{{ foo | first }}');
      expect(
          template.renderMap(<String, Object>{'foo': range(10)}), equals('0'));
    });

    test('force escape', () {
      final template = env.fromString('{{ x | forceescape }}');
      expect(template.renderMap(<String, Object>{'x': Markup.escaped('<div />')}),
          equals('&lt;div /&gt;'));
    });

    test('join', () {
      final template = env.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.renderMap(), equals('1|2|3'));
    });

    test('join attribute', () {
      final template =
          env.fromString('''{{ users | join(', ', 'username') }}''');
      expect(
          template.renderMap(<String, Object>{
            'users': <String>['foo', 'bar']
                .map((String name) => <String, String>{'username': name})
          }),
          equals('foo, bar'));
    });

    test('last', () {
      final template = env.fromString('''{{ foo|last }}''');
      expect(
          template.renderMap(<String, Object>{'foo': range(10)}), equals('9'));
    });

    test('length', () {
      final template = env.fromString('{{ "hello world"|length }}');
      expect(template.renderMap(), equals('11'));
    });

    test('lower', () {
      final template = env.fromString('''{{ "FOO"|lower }}''');
      expect(template.renderMap(), equals('foo'));
    });

    test('upper', () {
      final template = env.fromString('{{ "foo"|upper }}');
      expect(template.renderMap(), equals('FOO'));
    });
  });
}
