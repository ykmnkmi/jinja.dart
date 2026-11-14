@TestOn('vm || chrome')
library;

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
        '{% import "module" as m without context %}{{ m.test() }}',
      );
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
        '{% import "module" as m with context %}{{ m.test() }}',
      );
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
      tmpl = env.fromString('{% from "module" import test %}{{ test() }}');
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
        '{% from "module" import test without context %}{{ test() }}',
      );
      expect(tmpl.render({'foo': 42}), equals('[|23]'));
      tmpl = env.fromString(
        '{% from "module" import test with context %}{{ test() }}',
      );
      expect(tmpl.render({'foo': 42}), equals('[42|23]'));
    });

    test('import needs name', () {
      expect(
        () => env.fromString('{% from "foo" import bar %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar, baz %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
    });

    test('no trailing comma', () {
      expect(
        () => env.fromString('{% from "foo" import bar, %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
      expect(
        () => env.fromString('{% from "foo" import bar,, %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
      expect(
        () => env.fromString('{% from "foo" import, %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
    });

    test('trailing comma with context', () {
      expect(
        () => env.fromString('{% from "foo" import bar, baz with context %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar, baz, with context %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar, with context %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar, with, context %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar, with with context %}'),
        returnsNormally,
      );
      expect(
        () => env.fromString('{% from "foo" import bar,, with context %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
      expect(
        () => env.fromString('{% from "foo" import bar with context, %}'),
        throwsA(isA<TemplateSyntaxError>()),
      );
    });

    test('exports', () {}, skip: 'Not supported.');

    test('not exported', () {
      var tmpl = env.fromString(
        '{% from "module" import nothing %}{{ nothing() }}',
      );
      expect(
        () => tmpl.render(),
        throwsA(
          predicate<TemplateRuntimeError>(
            (error) =>
                error.message!.contains('does not export the requested name.'),
          ),
        ),
      );
    });

    test('import with globals', () {
      var tmpl = env.fromString(
        '{% import "module" as m %}{{ m.test() }}',
        globals: {'foo': 42},
      );
      expect(tmpl.render(), equals('[42|23]'));
      tmpl = env.fromString('{% import "module" as m %}{{ m.test() }}');
      expect(tmpl.render(), equals('[|23]'));
    });

    test('import with globals override', () {
      var tmpl = env.fromString(
        '{% set foo = 41 %}{% import "module" as m %}{{ m.test() }}',
        globals: {'foo': 42},
      );
      expect(tmpl.render(), equals('[42|23]'));
    });

    test('from import with globals', () {
      var tmpl = env.fromString(
        '{% from "module" import test %}{{ test() }}',
        globals: {'foo': 42},
      );
      expect(tmpl.render(), equals('[42|23]'));
    });
  });

  group('Import extra', () {
    test('imported modules have independent inheritance state', () {
      var templates = <String, String>{
        'base': '{% block content %}BASE{% endblock %}',
        'other': 'OTHER',
        'block':
            '{% block content %}MODULE{% endblock %}'
            '{% macro m() %}M{% endmacro %}',
        'extends': '{% extends "other" %}{% macro m() %}M{% endmacro %}',
        'inactive':
            '{% if false %}{% extends "other" %}{% endif %}'
            '{% macro m() %}M{% endmacro %}',
      };

      var imports = <String, String Function(String)>{
        'import': (name) => '{% import "$name" as mod %}',
        'import with context': (name) =>
            '{% import "$name" as mod with context %}',
        'from import': (name) => '{% from "$name" import m %}',
        'from import with context': (name) =>
            '{% from "$name" import m with context %}',
      };

      var env = Environment(loader: MapLoader(templates));

      imports.forEach((kind, statement) {
        expect(
          env.fromString('${statement('block')}{% extends "base" %}').render(),
          equals('BASE'),
          reason: '$kind: imported blocks do not override the caller',
        );
        expect(
          env
              .fromString('{% extends "base" %}${statement('extends')}')
              .render(),
          equals('BASE'),
          reason: '$kind: imported extends does not reuse the pending parent',
        );
        expect(
          env
              .fromString('{% extends "base" %}${statement('inactive')}')
              .render(),
          equals('BASE'),
          reason: '$kind: inactive imported extends does not consume parent',
        );
      });
    });

    test('without context clears the inherited caller context', () {
      var env = Environment(
        globals: {'g': 'G'},
        loader: MapLoader({
          'import':
              '{% import "inner" as inner without context %}'
              '{% macro show() %}{{ inner.show() }}{% endmacro %}',
          'from import':
              '{% from "inner" import show as inner_show without context %}'
              '{% macro show() %}{{ inner_show() }}{% endmacro %}',
          'inner':
              '{% macro show() %}'
              '{{ secret|default("MISSING") }}|{{ g }}{% endmacro %}',
          'mod': '{% set y = x + 41 %}',
        }),
      );

      for (var kind in ['import', 'from import']) {
        var tmpl = env.fromString(
          '{% set secret = "SECRET" %}'
          '{% import "$kind" as outer with context %}{{ outer.show() }}',
        );
        expect(tmpl.render(), equals('MISSING|G'), reason: kind);
      }

      var tmpl = env.fromString(
        '{% set x = 1 %}{% import "mod" as m with context %}{{ x }}|{{ m.y }}',
      );
      expect(tmpl.render(), equals('1|42'));
    });
  });
}
