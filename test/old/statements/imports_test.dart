import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  final env = Environment(
    globals: <String, dynamic>{'bar': 23},
    loader: MapLoader(<String, String>{
      // TODO: include after implementing modules
      // module: '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}'
      'header': '[{{ foo }}|{{ 23 }}]',
      'o_printer': '({{ o }})',
    }),
  );

  // TODO: add test: import

  group('include', () {
    final foo42 = <String, dynamic>{'foo': 42};

    test('context include', () {
      var template = env.fromString('{% include "header" %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" with context %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" without context %}');
      expect(template.renderMap(foo42), equals('[|23]'));
    });

    test('choise includes', () {
      var template = env.fromString('{% include ["missing", "header"] %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env
          .fromString('{% include ["missing", "missing2"] ignore missing %}');
      expect(template.renderMap(foo42), equals(''));

      template = env.fromString('{% include ["missing", "missing2"] %}');
      expect(() => template.renderMap(), throwsA(isA<TemplatesNotFound>()));

      // TODO: https://github.com/pallets/jinja/blob/master/tests/test_imports.py#L122

      void testIncludes(Template template, Map<String, dynamic> context) {
        context['foo'] = 42;
        expect(template.renderMap(context), equals('[42|23]'));
      }

      template = env.fromString('{% include ["missing", "header"] %}');
      testIncludes(template, <String, dynamic>{});
      template = env.fromString('{% include x %}');
      testIncludes(template, <String, dynamic>{
        'x': <String>['missing', 'header'],
      });
      template = env.fromString('{% include [x, "header"] %}');
      testIncludes(template, <String, dynamic>{'x': 'missing'});
      template = env.fromString('{% include x %}');
      testIncludes(template, <String, dynamic>{'x': 'header'});
      template = env.fromString('{% include [x] %}');
      testIncludes(template, <String, dynamic>{'x': 'header'});
    });

    test('include ignore missing', () {
      var template = env.fromString('{% include "missing" %}');
      expect(() => template.renderMap(), throwsA(isA<TemplateNotFound>()));

      for (var extra in <String>['', 'with context', 'without context']) {
        template =
            env.fromString('{% include "missing" ignore missing $extra %}');
        expect(template.renderMap(), equals(''));
      }
    });

    test('context include with overrides', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      final template = env.getTemplate('main');
      expect(template.renderMap(), equals('123'));
    });

    // TODO: add test: unoptimized scopes
    // TODO: add test: import from with context
  });
}
