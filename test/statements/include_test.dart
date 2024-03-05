@TestOn('vm || chrome')
library;

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

    test('choice includes', () {
      var tmpl = env.fromString('{% include ["missing", "header"] %}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));

      tmpl = env
          .fromString('{% include ["missing", "missing2"] ignore missing %}');
      expect(tmpl.render({'foo': 42}), equals(''));

      tmpl = env.fromString('{% include ["missing", "missing2"] %}');

      try {
        expect(tmpl.render({'foo': 42}), isA<Never>());
      } on TemplatesNotFound catch (error) {
        expect(error.name, contains('missing2'));
        expect(error.names, contains('missing'));
        expect(error.names, contains('missing2'));
      }

      void testIncludes(Template tmpl, [Map<String, Object?>? context]) {
        context ??= <String, Object?>{};
        context['foo'] = 42;
        expect(tmpl.render(context), '[42|23]');
      }

      tmpl = env.fromString('{% include ["missing", "header"] %}');
      testIncludes(tmpl);

      tmpl = env.fromString('{% include x %}');
      testIncludes(tmpl, {'x': 'missing,header'.split(',')});

      tmpl = env.fromString('{% include [x, "header"] %}');
      testIncludes(tmpl, {'x': 'missing'});

      tmpl = env.fromString('{% include x %}');
      testIncludes(tmpl, {'x': 'header'});

      tmpl = env.fromString('{% include [x] %}');
      testIncludes(tmpl, {'x': 'header'});
    });

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
