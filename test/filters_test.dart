import 'package:jinja/jinja.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('filter', () {
    var env = Environment();

    test('chaining', () {
      var template = env.fromString('''{{ ['<foo>', '<bar>']|first|upper|escape }}''');
      expect(template.renderMap(), equals('&lt;FOO&gt;'));
    });

    test('capitalize', () {
      var template = env.fromString('{{ "foo bar"|capitalize }}');
      expect(template.renderMap(), equals('Foo bar'));
    });

    test('center', () {
      var template = env.fromString('{{ "foo"|center(9) }}');
      expect(template.renderMap(), equals('   foo   '));
    });

    test('default', () {
      var template = env.fromString("{{ missing|default('no') }}|{{ false|default('no') }}|"
          "{{ false|default('no', true) }}|{{ given|default('no') }}");
      expect(template.renderMap(<String, Object>{'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('escape', () {
      var template = env.fromString('''{{ '<">&'|escape }}''');
      expect(template.renderMap(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('first', () {
      var template = env.fromString('{{ foo|first }}');
      expect(template.renderMap(<String, Object>{'foo': range(10)}), equals('0'));
    });

    test('force escape', () {
      var template = env.fromString('{{ x|forceescape }}');
      expect(template.renderMap(<String, Object>{'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });

    test('join', () {
      var template = env.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.renderMap(), equals('1|2|3'));
    });

    test('join attribute', () {
      var template = env.fromString('''{{ users|join(', ', 'username') }}''');
      expect(
          template.renderMap(<String, Object>{
            'users': <String>['foo', 'bar'].map((String name) => <String, String>{'username': name})
          }),
          equals('foo, bar'));
    });

    test('last', () {
      var template = env.fromString('''{{ foo|last }}''');
      expect(template.renderMap(<String, Object>{'foo': range(10)}), equals('9'));
    });

    test('length', () {
      var template = env.fromString('''{{ "hello world"|length }}''');
      expect(template.renderMap(), equals('11'));
    });

    test('lower', () {
      var template = env.fromString('''{{ "FOO"|lower }}''');
      expect(template.renderMap(), equals('foo'));
    });

    test('upper', () {
      var template = env.fromString('{{ "foo"|upper }}');
      expect(template.renderMap(), equals('FOO'));
    });
  });
}
