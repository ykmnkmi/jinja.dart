import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('set', () {
    final env = Environment(
      globals: {'bar': 23},
      loader: MapLoader({
        // TODO: module
        // module: '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}'
        'header': '[{{ foo }}|{{ 23 }}]',
        'o_printer': '({{ o }})',
      }),
    );

    test('context include', () {
      var template = env.fromSource('{% include "header" %}');
      expect(template.renderWr(foo: 42), equals('[42|23]'));

      template = env.fromSource('{% include "header" with context %}');
      expect(template.renderWr(foo: 42), equals('[42|23]'));

      template = env.fromSource('{% include "header" without context %}');
      expect(template.renderWr(foo: 42), equals('[|23]'));
    });

    test('choise includes', () {
      var template = env.fromSource('{% include ["missing", "header"] %}');
      expect(template.renderWr(foo: 42), equals('[42|23]'));

      template = env
          .fromSource('{% include ["missing", "missing2"] ignore missing %}');
      expect(template.renderWr(foo: 42), equals(''));

      template = env.fromSource('{% include ["missing", "missing2"] %}');
      expect(() => template.render(), throwsA(isA<TemplatesNotFound>()));
    });

    // TODO: https://github.com/pallets/jinja/blob/master/tests/test_imports.py#L122
  });
}
