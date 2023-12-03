import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Import', () {
    var env = Environment(
      globals: {'bar': 23},
      loader: MapLoader({
        'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
        'header': '[{{ foo }}|{{ 23 }}]',
        'o_printer': '({{ o }})',
      }),
    );

    test('context import', () {
      var tmpl = env.fromString('{% import "module" as m %}{{ m.test() }}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
          '{% import "module" as m without context %}{{ m.test() }}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env
          .fromString('{% import "module" as m with context %}{{ m.test() }}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
      tmpl = env.fromString('{% from "module" import test %}{{ test() }}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
          '{% from "module" import test without context %}{{ test() }}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
          '{% from "module" import test with context %}{{ test() }}');
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
    });

    test('import needs name', () {
      env.fromString('{% from "foo" import bar %}');
      env.fromString('{% from "foo" import bar, baz %}');

      expect(() => env.fromString('{% from "foo" import %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });
  });
}
