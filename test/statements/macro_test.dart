import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Macro', () {
    late Environment environment;

    setUp(() {
      environment = Environment(trimBlocks: true);
    });

    test('simple', () {
      var tmpl = environment.fromString('''
{% macro say_hello(name) %}Hello {{ name }}!{% endmacro %}
{{ say_hello('Peter') }}''');
      expect(tmpl.render(), equals('Hello Peter!'));
    });

    test('scoping', () {
      var tmpl = environment.fromString('''
{% macro level1(data1) %}
{% macro level2(data2) %}{{ data1 }}|{{ data2 }}{% endmacro %}
{{ level2('bar') }}{% endmacro %}
{{ level1('foo') }}''');
      expect(tmpl.render(), equals('foo|bar'));
    });

    test('arguments', () {
      var tmpl = environment.fromString('''
{% macro m(a, b, c='c', d='d') %}{{ a }}|{{ b }}|{{ c }}|{{ d }}{% endmacro %}
{{ m('a', 'b') }}|{{ m(1, 2, c=3) }}''');
      expect(tmpl.render(), equals('a|b|c|d|1|2|3|d'));
    });

    test('arguments defaults nonsense', () {
      expect(() {
        environment.fromString('''
{% macro m(a, b=1, c) %}a={{ a }}, b={{ b }}, c={{ c }}{% endmacro %}''');
      }, throwsA(isA<TemplateSyntaxError>()));
    });

    test('caller defaults nonsense', () {
      expect(() {
        environment.fromString('''
{% macro a() %}{{ caller() }}{% endmacro %}
{% call(x, y=1, z) a() %}{% endcall %}''');
      }, throwsA(isA<TemplateSyntaxError>()));
    });

    test('varargs', () {
      var tmpl = environment.fromString('''
{% macro test() %}{{ varargs|join('|') }}{% endmacro -%}
{{ test(1, 2, 3) }}''');
      expect(tmpl.render(), equals('1|2|3'));
    }, skip: true);

    test('simple call', () {
      var tmpl = environment.fromString('''
{% macro test() %}[[{{ caller() }}]]{% endmacro -%}
{% call test() %}data{% endcall %}''');
      expect(tmpl.render(), equals('[[data]]'));
    }, skip: true);

    test('complex call', () {
      var tmpl = environment.fromString('''
{% macro test() %}[[{{ caller('data') }}]]{% endmacro -%}
{% call(data) test() %}{{ data }}{% endcall %}''');
      expect(tmpl.render(), equals('[[data]]'));
    }, skip: true);

    test('caller undefined', () {
      var tmpl = environment.fromString('''
{% set caller = 42 -%}
{% macro test() %}{{ caller is eq null }}{% endmacro -%}
{{ test() }}''');
      expect(tmpl.render(), equals('true'));
    });
  });
}
