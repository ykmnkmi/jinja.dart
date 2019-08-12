import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  final env = Environment();

  test('raw', () {
    final template = env.fromSource('{% raw %}foo{% endraw %}|'
        '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
    expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
  });

  test('raw2', () {
    final template = env.fromSource('1  {%- raw -%}   2   {%- endraw -%}   3');
    expect(template.render(), equals('123'));
  });

  test('raw3', () {
    final env = Environment(leftStripBlocks: true, trimBlocks: true);
    final template =
        env.fromSource('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
    expect(template.renderWr(baz: 'test'),
        equals('bar\n\n  {{baz}}2 spaces\nfoo'));
  });

  test('raw4', () {
    final env = Environment(leftStripBlocks: true);
    final template = env.fromSource(
        'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
    expect(template.render(), equals('bar2 spaces\n spacefoo'));
  });
}
