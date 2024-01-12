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
      expect(
          () => env.fromString('{% from "foo" import bar %}'), returnsNormally);
      expect(() => env.fromString('{% from "foo" import bar, baz %}'),
          returnsNormally);
      expect(() => env.fromString('{% from "foo" import %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('no trailing comma', () {
      expect(() => env.fromString('{% from "foo" import bar, %}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{% from "foo" import bar,, %}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{% from "foo" import, %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('trailing comma with context', () {
      expect(
          () => env.fromString('{% from "foo" import bar, baz with context %}'),
          returnsNormally);
      expect(
          () =>
              env.fromString('{% from "foo" import bar, baz, with context %}'),
          returnsNormally);
      expect(() => env.fromString('{% from "foo" import bar, with context %}'),
          returnsNormally);
      expect(() => env.fromString('{% from "foo" import bar, with, context %}'),
          returnsNormally);
      expect(
          () =>
              env.fromString('{% from "foo" import bar, with with context %}'),
          returnsNormally);
      expect(() => env.fromString('{% from "foo" import bar,, with context %}'),
          throwsA(isA<TemplateSyntaxError>()));
      expect(() => env.fromString('{% from "foo" import bar with context, %}'),
          throwsA(isA<TemplateSyntaxError>()));
    });

    test('exports', () {}, skip: 'Not supported.');

    test('not exported', () {
      var tmpl =
          env.fromString('{% from "module" import nothing %}{{ nothing() }}');
      expect(
          () => tmpl.render(),
          throwsA(predicate<TemplateRuntimeError>((error) =>
              error.message!.contains('does not export the requested name.'))));
    });

    test('import with globals', () {
      var tmpl = env.fromString('{% import "module" as m %}{{ m.test() }}',
          globals: {'foo': 42});
      expect(tmpl.render(), equals('[42|23]'));
      tmpl = env.fromString('{% import "module" as m %}{{ m.test() }}');
      expect(tmpl.render(), equals('[|23]'));
    });

    test('import with globals override', () {
      var tmpl = env.fromString(
          '{% set foo = 41 %}{% import "module" as m %}{{ m.test() }}',
          globals: {'foo': 42});
      expect(tmpl.render(), equals('[42|23]'));
    });

    test('from import with globals', () {
      var tmpl = env.fromString('{% from "module" import test %}{{ test() }}',
          globals: {'foo': 42});
      expect(tmpl.render(), equals('[42|23]'));
    });
  });
}
