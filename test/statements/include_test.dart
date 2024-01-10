import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

import '../environment.dart';

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
      env.render('{% include "header" %}',
          data: {'foo': 42}, equals: '[42|23]');

      env.render('{% include "header" with context %}',
          data: {'foo': 42}, equals: '[42|23]');

      env.render('{% include "header" without context %}',
          data: {'foo': 42}, equals: '[|23]');
    });

    // TODO: add test: choice_includes

    test('include ignore missing', () {
      env.renderThrows<TemplateNotFound>('{% include "missing" %}');
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
