import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Include', () {
    late final environment = Environment(
      loader: MapLoader({
        'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
        'header': '[{{ foo }}|{{ 23 }}]',
        'o_printer': '({{ o }})',
      }),
      globals: {'bar': 23},
    );

    Template parse(String source) {
      return environment.fromString(source);
    }

    String render(String source, [Map<String, Object?>? data]) {
      return parse(source).render(data);
    }

    test('context include', () {
      expect(render('{% include "header" %}', {'foo': 42}), equals('[42|23]'));
      expect(render('{% include "header" with context %}', {'foo': 42}),
          equals('[42|23]'));
      expect(render('{% include "header" without context %}', {'foo': 42}),
          equals('[|23]'));
    });

    test('include ignoring missing', () {
      expect(() => render('{% include "missing" %}'),
          throwsA(isA<TemplateNotFound>()));
      expect(render('{% include "missing" ignore missing "" %}'), equals(''));
      expect(render('{% include "missing" ignore missing "with context" %}'),
          equals(''));
      expect(render('{% include "missing" ignore missing "without context" %}'),
          equals(''));
    });

    test('context include with overrides', () {
      var environment = Environment(
        loader: MapLoader({
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      expect(environment.getTemplate('main').render(), equals('123'));
    });

    // TODO: after macro: add test: unoptimized_scopes
    // TODO: after macro: add test: import_from_with_context
  });
}
