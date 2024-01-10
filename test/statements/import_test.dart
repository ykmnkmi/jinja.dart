import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

import '../environment.dart';

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
      env.render('{% import "module" as m %}{{ m.test() }}',
          data: {'foo': 42}, equals: '[|23]');

      env.render('{% import "module" as m without context %}{{ m.test() }}',
          data: {'foo': 42}, equals: '[|23]');

      env.render('{% import "module" as m with context %}{{ m.test() }}',
          data: {'foo': 42}, equals: '[42|23]');

      env.render('{% from "module" import test %}{{ test() }}',
          data: {'foo': 42}, equals: '[|23]');

      env.render('{% from "module" import test without context %}{{ test() }}',
          data: {'foo': 42}, equals: '[|23]');

      env.render('{% from "module" import test with context %}{{ test() }}',
          data: {'foo': 42}, equals: '[42|23]');
    });

    test('import needs name', () {
      env.from('{% from "foo" import bar %}');

      env.from('{% from "foo" import bar, baz %}');

      env.fromThrows<TemplateSyntaxError>('{% from "foo" import %}');
    });

    test('no trailing comma', () {
      env.fromThrows<TemplateSyntaxError>('{% from "foo" import bar, %}');

      env.fromThrows<TemplateSyntaxError>('{% from "foo" import bar,, %}');

      env.fromThrows<TemplateSyntaxError>('{% from "foo" import, %}');
    });

    test('trailing comma with context', () {
      env.from('{% from "foo" import bar, baz with context %}');

      env.from('{% from "foo" import bar, baz, with context %}');

      env.from('{% from "foo" import bar, with context %}');

      env.from('{% from "foo" import bar, with, context %}');

      env.from('{% from "foo" import bar, with with context %}');

      env.fromThrows<TemplateSyntaxError>(
          '{% from "foo" import bar,, with context %}');

      env.fromThrows<TemplateSyntaxError>(
          '{% from "foo" import bar with context, %}');
    });

    test('exports', () {}, skip: 'Not supported.');

    test('not exported', () {
      env.renderThrows<TemplateRuntimeError>(
          '{% from "module" import nothing %}{{ nothing() }}',
          predicate: (error) =>
              error.message!.contains('does not export the requested name.'));
    });

    test('import with globals', () {
      env.render('{% import "module" as m %}{{ m.test() }}',
          globals: {'foo': 42}, equals: '[42|23]');

      env.render('{% import "module" as m %}{{ m.test() }}', equals: '[|23]');
    });

    test('import with globals override', () {
      env.render('{% set foo = 41 %}{% import "module" as m %}{{ m.test() }}',
          globals: {'foo': 42}, equals: '[42|23]');
    });

    test('from import with globals', () {
      env.render('{% from "module" import test %}{{ test() }}',
          globals: {'foo': 42}, equals: '[42|23]');
    });
  });
}
