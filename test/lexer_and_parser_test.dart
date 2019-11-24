import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('lexer', () {
    Environment env = Environment();

    test('raw', () {
      Template template = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      Template template = env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      Environment env = Environment(leftStripBlocks: true, trimBlocks: true);
      Template template = env.fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.renderWr(baz: 'test'), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      Environment env = Environment(
        blockStart: '{%',
        blockEnd: '%}',
        variableStart: r'${',
        variableEnd: '}',
      );

      Template template = env.fromString(r'''{% for item in seq
            %}${{'foo': item} | upper}{% endfor %}''');
      expect(template.renderWr(seq: <int>[0, 1, 2]), equals("{'FOO': 0}{'FOO': 1}{'FOO': 2}"));
    });

    test('comments', () {
      Environment env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: '{',
        variableEnd: '}',
      );

      Template template = env.fromString('''\
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(template.renderWr(seq: <int>[0, 1, 2]), equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      for (String char in <String>[r'\0', r'\2668', r'\xe4', r'\t', r'\r', r'\n']) {
        Template template = env.fromString('{{ ${repr(char)} }}');
        expect(template.render(), equals(char));
      }

      // TODO: * poor dart
      // expect(env.fromString('{{ "\N{HOT SPRINGS}" }}').render(), equals('\u2668'));
    });
  });

  group('leftStripBlocks', () {
    Environment env = Environment();

    test('left strip', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals('\n'));
    });

    test('left strip trim', () {
      Environment env = Environment(leftStripBlocks: true, trimBlocks: true);
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals(''));
    });

    test('no left strip', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('left strip blocks false with no left strip', () {
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));
      template = env.fromString('    {%+ if True %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });
  });
}
