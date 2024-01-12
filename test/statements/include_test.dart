import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Include', () {
    var env = Environment(
      globals: {'bar': 23},
      loader: MapLoader({
        'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
        'header': '[{{ foo }}|{{ 23 }}]',
        'o_printer': '({{ o }})',
      }),
    );

    test('context include', () {
      var tmpl = env.fromString('{% include "header" %}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));

      tmpl = env.fromString('{% include "header" with context %}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));

      tmpl = env.fromString('{% include "header" without context %}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
    });

    // TODO: add test: choice_includes

    test('include ignore missing', () {
      var tmpl = env.fromString('{% include "missing" %}');
      expect(() => tmpl.render(), throwsA(isA<TemplateNotFound>()));
    });

    test('context include with overrides', () {
      var env = Environment(
        loader: MapLoader({
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      var tmpl = env.getTemplate('main');
      expect(tmpl.render(), equals('123'));
    });

    // TODO: add test: unoptimized_scopes
    // TODO: add test: import_from_with_context
  });
}
