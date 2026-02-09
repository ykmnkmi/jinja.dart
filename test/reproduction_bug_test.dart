import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Macro Recursion and Order', () {
    test('recursive macro defined after caller works after hoisting', () {
      var env = Environment();
      // 'render_list' calls 'render_item' which is defined later.
      const templateSrc = '''
{%- macro render_list(items) -%}
    {%- for item in items -%}
        {{ render_item(item) }}
    {%- endfor -%}
{%- endmacro -%}

{%- macro render_item(item) -%}
    {{ item.name }}
    {%- if item.children -%}
        {%- for child in item.children -%}
            {{ render_item(child) }}
        {%- endfor -%}
    {%- endif -%}
{%- endmacro -%}

{{ render_list(data) }}''';

      var template = env.fromString(templateSrc);
      var data = [
        {
          'name': 'A',
          'children': [
            {'name': 'A1'}
          ]
        },
        {'name': 'B'}
      ];

      var result = template.render({'data': data});
      expect(result.trim(), equals('AA1B'));
    });
  });

  group('Sequence Test', () {
    test('sequence test is available', () {
      var env = Environment();
      // 'sequence' test should be available now.
      expect(
          env.fromString('{{ [1, 2] is sequence }}').render(), equals('true'));
      expect(env.fromString('{{ 1 is sequence }}').render(), equals('false'));
    });
  });
}
