import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('parser', () {
    Environment env = Environment();

    test('raw', () {
      Template template = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      Template template =
          env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      Environment env = Environment(leftStripBlocks: true, trimBlocks: true);
      Template template = env
          .fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.render(<String, Object>{'baz': 'test'}),
          equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString(
          'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
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
      expect(
          template.render(<String, Object>{
            'seq': <int>[0, 1, 2]
          }),
          equals("{'FOO': 0}{'FOO': 1}{'FOO': 2}"));
    });
  });
}
