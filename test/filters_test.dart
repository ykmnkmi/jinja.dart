import 'package:jinja/jinja.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('filter', () {
    Environment env = Environment();

    test('chaining', () {
      Template template = env.fromString('''{{ ['<foo>', '<bar>']|first|upper|escape }}''');
      expect(template.render(), equals('&lt;FOO&gt;'));
    });

    test('capitalize', () {
      Template template = env.fromString('{{ "foo bar"|capitalize }}');
      expect(template.render(), equals('Foo bar'));
    });

    test('center', () {
      Template template = env.fromString('{{ "foo"|center(9) }}');
      expect(template.render(), equals('   foo   '));
    });

    test('default', () {
      Template template = env.fromString("{{ missing|default('no') }}|{{ false|default('no') }}|"
          "{{ false|default('no', true) }}|{{ given|default('no') }}");
      expect(template.render(<String, Object>{'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('escape', () {
      Template template = env.fromString('''{{ '<">&'|escape }}''');
      expect(template.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('first', () {
      Template template = env.fromString('{{ foo|first }}');
      expect(template.render(<String, Object>{'foo': range(10)}), equals('0'));
    });

    test('force escape', () {
      Template template = env.fromString('{{ x|forceescape }}');
      expect(template.render(<String, Object>{'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });

    test('join', () {
      Template template = env.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.render(), equals('1|2|3'));
    });

    test('join attribute', () {
      Template template = env.fromString('''{{ users|join(', ', 'username') }}''');
      expect(
          template.render(<String, Object>{
            'users': <String>['foo', 'bar'].map((String name) => <String, String>{'username': name})
          }),
          equals('foo, bar'));
    });

    test('last', () {
      Template template = env.fromString('''{{ foo|last }}''');
      expect(template.render(<String, Object>{'foo': range(10)}), equals('9'));
    });

    test('length', () {
      Template template = env.fromString('''{{ "hello world"|length }}''');
      expect(template.render(), equals('11'));
    });

    test('lower', () {
      Template template = env.fromString('''{{ "FOO"|lower }}''');
      expect(template.render(), equals('foo'));
    });

    test('upper', () {
      Template template = env.fromString('{{ "foo"|upper }}');
      expect(template.render(), equals('FOO'));
    });
  });
}
