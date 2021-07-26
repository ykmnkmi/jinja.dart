import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Include', () {
    late final env = Environment(
      loader: MapLoader({
        'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
        'header': '[{{ foo }}|{{ 23 }}]',
        'o_printer': '({{ o }})',
      }),
      globals: {'bar': 23},
    );

    test('context include', () {
      var tmpl = env.fromString('{% include "header" %}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
      tmpl = env.fromString('{% include "header" with context %}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
      tmpl = env.fromString('{% include "header" without context %}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
    });

    test('include ignoring missing', () {
      final tmpl = env.fromString('{% include "missing" %}');
      expect(() => tmpl.render(), throwsA(isA<TemplateNotFound>()));
    });

    test('context include with overrides', () {
      final env = Environment(
        loader: MapLoader({
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      final tmpl = env.getTemplate('main');
      expect(tmpl.render(), equals('123'));
    });

    // TODO: after macro: add test: unoptimized_scopes
    // TODO: after macro: add test: import_from_with_context
  });
}
