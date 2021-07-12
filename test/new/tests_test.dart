import 'dart:collection';

import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class MyMap extends MapBase<Object?, Object?> {
  @override
  Iterable<Object?> get keys {
    throw UnimplementedError();
  }

  @override
  Object? operator [](Object? key) {
    throw UnimplementedError();
  }

  @override
  void operator []=(Object? key, Object? value) {
    throw UnimplementedError();
  }

  @override
  void clear() {
    throw UnimplementedError();
  }

  @override
  Object? remove(Object? key) {
    throw UnimplementedError();
  }
}

void main() {
  group('Test', () {
    test('defined', () {
      expect(render('{{ missing is defined }}|{{ true is defined }}'),
          equals('false|true'));
    });

    test('even', () {
      expect(render('{{ 1 is even }}|{{ 2 is even }}'), equals('false|true'));
    });

    test('odd', () {
      expect(render('{{ 1 is odd }}|{{ 2 is odd }}'), equals('true|false'));
    });

    test('lower', () {
      expect(render('{{ "foo" is lower }}|{{ "FOO" is lower }}'),
          equals('true|false'));
    });

    test('types', () {
      expect(render('{{ none is none }}'), equals('true'));
      expect(render('{{ false is none }}'), equals('false'));
      expect(render('{{ true is none }}'), equals('false'));
      expect(render('{{ 42 is none }}'), equals('false'));
      expect(render('{{ none is true }}'), equals('false'));
      expect(render('{{ false is true }}'), equals('false'));
      expect(render('{{ true is true }}'), equals('true'));
      expect(render('{{ 0 is true }}'), equals('false'));
      expect(render('{{ 1 is true }}'), equals('false'));
      expect(render('{{ 42 is true }}'), equals('false'));
      expect(render('{{ none is false }}'), equals('false'));
      expect(render('{{ false is false }}'), equals('true'));
      expect(render('{{ true is false }}'), equals('false'));
      expect(render('{{ 0 is false }}'), equals('false'));
      expect(render('{{ 1 is false }}'), equals('false'));
      expect(render('{{ 42 is false }}'), equals('false'));
      expect(render('{{ none is boolean }}'), equals('false'));
      expect(render('{{ false is boolean }}'), equals('true'));
      expect(render('{{ true is boolean }}'), equals('true'));
      expect(render('{{ 0 is boolean }}'), equals('false'));
      expect(render('{{ 1 is boolean }}'), equals('false'));
      expect(render('{{ 42 is boolean }}'), equals('false'));
      expect(render('{{ 0.0 is boolean }}'), equals('false'));
      expect(render('{{ 1.0 is boolean }}'), equals('false'));
      expect(render('{{ 3.14159 is boolean }}'), equals('false'));
      expect(render('{{ none is integer }}'), equals('false'));
      expect(render('{{ false is integer }}'), equals('false'));
      expect(render('{{ true is integer }}'), equals('false'));
      expect(render('{{ 42 is integer }}'), equals('true'));
      expect(render('{{ 3.14159 is integer }}'), equals('false'));
      expect(render('{{ (10 ** 100) is integer }}'), equals('true'));
      expect(render('{{ none is float }}'), equals('false'));
      expect(render('{{ false is float }}'), equals('false'));
      expect(render('{{ true is float }}'), equals('false'));
      expect(render('{{ 42 is float }}'), equals('false'));
      expect(render('{{ 4.2 is float }}'), equals('true'));
      expect(render('{{ (10 ** 100) is float }}'), equals('false'));
      expect(render('{{ none is number }}'), equals('false'));
      // difference: false is not num
      expect(render('{{ false is number }}'), equals('false'));
      // difference: true is not num
      expect(render('{{ true is number }}'), equals('false'));
      expect(render('{{ 42 is number }}'), equals('true'));
      expect(render('{{ 3.14159 is number }}'), equals('true'));
      // not supported: complex
      // expect(tempalte('{{ complex is number }}'), equals('true'));
      expect(render('{{ (10 ** 100) is number }}'), equals('true'));
      expect(render('{{ none is string }}'), equals('false'));
      expect(render('{{ false is string }}'), equals('false'));
      expect(render('{{ true is string }}'), equals('false'));
      expect(render('{{ 42 is string }}'), equals('false'));
      expect(render('{{ "foo" is string }}'), equals('true'));
      expect(render('{{ none is sequence }}'), equals('false'));
      expect(render('{{ false is sequence }}'), equals('false'));
      expect(render('{{ 42 is sequence }}'), equals('false'));
      expect(render('{{ "foo" is sequence }}'), equals('true'));
      expect(render('{{ [] is sequence }}'), equals('true'));
      expect(render('{{ [1, 2, 3] is sequence }}'), equals('true'));
      expect(render('{{ {} is sequence }}'), equals('true'));
      expect(render('{{ none is mapping }}'), equals('false'));
      expect(render('{{ false is mapping }}'), equals('false'));
      expect(render('{{ 42 is mapping }}'), equals('false'));
      expect(render('{{ "foo" is mapping }}'), equals('false'));
      expect(render('{{ [] is mapping }}'), equals('false'));
      expect(render('{{ {} is mapping }}'), equals('true'));
      expect(render('{{ md is mapping }}', {'md': MyMap()}), equals('true'));
      expect(render('{{ none is iterable }}'), equals('false'));
      expect(render('{{ false is iterable }}'), equals('false'));
      expect(render('{{ 42 is iterable }}'), equals('false'));
      // difference: string is not iterable
      expect(render('{{ "foo" is iterable }}'), equals('false'));
      expect(render('{{ [] is iterable }}'), equals('true'));
      // difference: map is not iterable
      expect(render('{{ {} is iterable }}'), equals('false'));
      expect(render('{{ range(5) is iterable }}'), equals('true'));
      expect(render('{{ none is callable }}'), equals('false'));
      expect(render('{{ false is callable }}'), equals('false'));
      expect(render('{{ 42 is callable }}'), equals('false'));
      expect(render('{{ "foo" is callable }}'), equals('false'));
      expect(render('{{ [] is callable }}'), equals('false'));
      expect(render('{{ {} is callable }}'), equals('false'));
      expect(render('{{ range is callable }}'), equals('true'));
    });

    test('upper', () {
      expect(render('{{ "FOO" is upper }}|{{ "foo" is upper }}'),
          equals('true|false'));
    });

    test('equal to', () {
      final data = {'foo': 12, 'bar': 'baz'};
      expect(render('{{ foo is eq 12 }}', data), equals('true'));
      expect(render('{{ foo is eq 0 }}', data), equals('false'));
      expect(render('{{ foo is eq (3 * 4) }}', data), equals('true'));
      expect(render('{{ bar is eq "baz" }}', data), equals('true'));
      expect(render('{{ bar is eq "zab" }}', data), equals('false'));
      expect(render('{{ bar is eq ("ba" + "z") }}', data), equals('true'));
      expect(render('{{ bar is eq bar }}', data), equals('true'));
      expect(render('{{ bar is eq foo }}', data), equals('false'));
    });

    test('compare aliases', () {
      expect(render('{{ 2 is eq 2 }}'), equals('true'));
      expect(render('{{ 2 is eq 3 }}'), equals('false'));
      expect(render('{{ 2 is ne 3 }}'), equals('true'));
      expect(render('{{ 2 is ne 2 }}'), equals('false'));
      expect(render('{{ 2 is lt 3 }}'), equals('true'));
      expect(render('{{ 2 is lt 2 }}'), equals('false'));
      expect(render('{{ 2 is le 2 }}'), equals('true'));
      expect(render('{{ 2 is le 1 }}'), equals('false'));
      expect(render('{{ 2 is gt 1 }}'), equals('true'));
      expect(render('{{ 2 is gt 2 }}'), equals('false'));
      expect(render('{{ 2 is ge 2 }}'), equals('true'));
      expect(render('{{ 2 is ge 3 }}'), equals('false'));
    });

    test('same as', () {
      expect(
          render('{{ foo is sameas false }}|{{ 0 is sameas false }}',
              {'foo': false}),
          equals('true|false'));
    });

    test('no paren for arg 1', () {
      expect(render('{{ foo is sameas none }}', {'foo': null}), equals('true'));
    });

    test('escaped', () {
      expect(
          render('{{  x is escaped }}|{{ y is escaped  }}',
              {'x': 'foo', 'y': Markup('foo')}),
          equals('false|true'));
    });

    test('greater than', () {
      expect(render('{{ 1 is greaterthan 0 }}|{{ 0 is greaterthan 1 }}'),
          equals('true|false'));
    });

    test('less than', () {
      expect(render('{{ 0 is lessthan 1 }}|{{ 1 is lessthan 0 }}'),
          equals('true|false'));
    });

    test('multiple test', () {
      final items = <Object?>[];

      bool matching(Object? x, Object? y) {
        items.add(<Object?>[x, y]);
        return false;
      }

      final source = '{{ "us-west-1" is matching "(us-east-1|ap-northeast-1)"'
          ' or "stage" is matching "(dev|stage)" }}';

      final result = Environment(tests: {'matching': matching})
          .fromString(source)
          .render();

      expect(result, equals('false'));
      expect(items[0], equals(['us-west-1', '(us-east-1|ap-northeast-1)']));
      expect(items[1], equals(['stage', '(dev|stage)']));
    });

    test('in', () {
      expect(render('{{ "o" is in "foo" }}'), equals('true'));
      expect(render('{{ "foo" is in "foo" }}'), equals('true'));
      expect(render('{{ "b" is in "foo" }}'), equals('false'));
      expect(render('{{ 1 is in ((1, 2)) }}'), equals('true'));
      expect(render('{{ 3 is in ((1, 2)) }}'), equals('false'));
      expect(render('{{ 1 is in [1, 2] }}'), equals('true'));
      expect(render('{{ 3 is in [1, 2] }}'), equals('false'));
      expect(render('{{ "foo" is in {"foo": 1} }}'), equals('true'));
      expect(render('{{ "baz" is in {"bar": 1} }}'), equals('false'));
    });
  });
}
