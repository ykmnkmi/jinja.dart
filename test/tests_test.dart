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
      var tmpl = env.fromString('{{ missing is defined }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is defined }}');
      expect(tmpl.render(), equals('true'));
    });

    test('even', () {
      var tmpl = env.fromString('{{ 1 is even }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is even }}');
      expect(tmpl.render(), equals('true'));
    });

    test('odd', () {
      var tmpl = env.fromString('{{ 1 is odd }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is odd }}');
      expect(tmpl.render(), equals('false'));
    });

    test('lower', () {
      var tmpl = env.fromString('{{ "foo" is lower }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ "FOO" is lower }}');
      expect(tmpl.render(), equals('false'));
    });

    test('types', () {
      var tmpl = env.fromString('{{ none is none }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ false is none }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is none }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is none }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none is true }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is true }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is true }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 0 is true }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1 is true }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is true }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none is false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is false }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ true is false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 0 is false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1 is false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is false }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is boolean }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ true is boolean }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 0 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 0.0 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1.0 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 3.14159 is boolean }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none is integer }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is integer }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is integer }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is integer }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 3.14159 is integer }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ (10 ** 100) is integer }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ none is float }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is float }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is float }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is float }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 4.2 is float }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ (10 ** 100) is float }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ none is number }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is number }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is number }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is number }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 3.14159 is number }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ (10 ** 100) is number }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ none is string }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is string }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ true is string }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is string }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is string }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ none is list }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is list }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is list }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is list }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ [] is list }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ [1, 2, 3] is list }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ none is map }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is map }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is map }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is map }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ [] is map }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ {} is map }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ mydict is map }}');
      expect(tmpl.render({'mydict': MyMap()}), equals('true'));
      tmpl = env.fromString('{{ none is iterable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is iterable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is iterable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is iterable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ [] is iterable }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ {} is iterable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ range(5) is iterable }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ none is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ false is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 42 is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ [] is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ {} is callable }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ range is callable }}');
      expect(tmpl.render(), equals('true'));
    });

    test('upper', () {
      var tmpl = env.fromString('{{ "FOO" is upper }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ "foo" is upper }}');
      expect(tmpl.render(), equals('false'));
    });

    test('equal to', () {
      var data = {'foo': 12, 'bar': 'baz'};
      var tmpl = env.fromString('{{ foo is eq 12 }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ foo is eq 0 }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ foo is eq (3 * 4) }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ bar is eq "baz" }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ bar is eq "zab" }}');
      expect(tmpl.render(data), equals('false'));
      tmpl = env.fromString('{{ bar is eq ("ba" + "z") }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ bar is eq bar }}');
      expect(tmpl.render(data), equals('true'));
      tmpl = env.fromString('{{ bar is eq foo }}');
      expect(tmpl.render(data), equals('false'));
    });

    test('compare aliases', () {
      var tmpl = env.fromString('{{ 2 is eq 2 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is eq 3 }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is ne 3 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is ne 2 }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is lt 3 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is lt 2 }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is le 2 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is le 1 }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is gt 1 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is gt 2 }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 2 is ge 2 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 2 is ge 3 }}');
      expect(tmpl.render(), equals('false'));
    });

    test('same as', () {
      var tmpl = env.fromString('{{ foo is sameas false }}');
      expect(tmpl.render({'foo': false}), equals('true'));
      tmpl = env.fromString('{{ 0 is sameas false }}');
      expect(tmpl.render(), equals('false'));
    });

    test('no paren for arg 1', () {
      var tmpl = env.fromString('{{ foo is sameas none }}');
      expect(tmpl.render({'foo': null}), equals('true'));
    });

    test('escaped', () {
      var tmpl = env.fromString('{{  x is escaped }}');
      expect(tmpl.render({'x': 'foo'}), equals('false'));
      tmpl = env.fromString('{{ y is escaped  }}');
      expect(tmpl.render({'y': Markup('foo')}), equals('true'));
    });

    test('greater than', () {
      var tmpl = env.fromString('{{ 1 is greaterthan 0 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 0 is greaterthan 1 }}');
      expect(tmpl.render(), equals('false'));
    });

    test('less than', () {
      var tmpl = env.fromString('{{ 0 is lessthan 1 }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 1 is lessthan 0 }}');
      expect(tmpl.render(), equals('false'));
    });

    test('multiple test', () {
      var items = <Object?>[];

      bool matching(Object? x, Object? y) {
        items.add([x, y]);
        return false;
      }

      var env = Environment(tests: {'matching': matching});
      var tmpl = env
          .fromString('{{ "us-west-1" is matching "(us-east-1|ap-northeast-1)"'
              ' or "stage" is matching "(dev|stage)" }}');
      var result = tmpl.render();
      expect(result, equals('false'));
      expect(items[0], equals(['us-west-1', '(us-east-1|ap-northeast-1)']));
      expect(items[1], equals(['stage', '(dev|stage)']));
    });

    test('in', () {
      var tmpl = env.fromString('{{ "o" is in "foo" }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ "foo" is in "foo" }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ "b" is in "foo" }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1 is in ((1, 2)) }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 3 is in ((1, 2)) }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ 1 is in [1, 2] }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ 3 is in [1, 2] }}');
      expect(tmpl.render(), equals('false'));
      tmpl = env.fromString('{{ "foo" is in {"foo": 1} }}');
      expect(tmpl.render(), equals('true'));
      tmpl = env.fromString('{{ "baz" is in {"bar": 1} }}');
      expect(tmpl.render(), equals('false'));
    });

    test('name undefined', () {
      expect(
          () => env.fromString('{{ x is f }}'),
          throwsA(predicate<TemplateAssertionError>(
              (error) => error.message == 'no test named \'f\'')));
    });

    test('name undefined in if', () {
      var tmpl = env.fromString('{% if x is defined %}{{ x is f }}{% endif %}');
      expect(tmpl.render(), equals(''));
      expect(
          () => tmpl.render({'x': 1}),
          throwsA(predicate<TemplateAssertionError>(
              (error) => error.message == 'no test named \'f\'')));
    });

    test('is filter', () {
      expect(env.callTest('filter', ['string']), isTrue);
      expect(env.callTest('filter', ['badName']), isFalse);
    });

    test('is test', () {
      expect(env.callTest('test', ['number']), isTrue);
      expect(env.callTest('test', ['badName']), isFalse);
    });
  });
}
