import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  final Environment env = Environment(
    globals: <String, Object>{'bar': 23},
    loader: MapLoader(<String, String>{
      // TODO: включить после реализаци модулей
      // module: '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}'
      'header': '[{{ foo }}|{{ 23 }}]',
      'o_printer': '({{ o }})',
    }),
  );

  // TODO: добавить тест: import

  group('include', () {
    final Map<String, Object> foo42 = <String, Object>{'foo': 42};

    test('context include', () {
      Template template = env.fromString('{% include "header" %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" with context %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" without context %}');
      expect(template.renderMap(foo42), equals('[|23]'));
    });

    test('choise includes', () {
      Template template = env.fromString('{% include ["missing", "header"] %}');
      expect(template.renderMap(foo42), equals('[42|23]'));

      template = env
          .fromString('{% include ["missing", "missing2"] ignore missing %}');
      expect(template.renderMap(foo42), equals(''));

      template = env.fromString('{% include ["missing", "missing2"] %}');
      expect(() => template.renderMap(), throwsA(isA<TemplatesNotFound>()));

      // TODO: ссылка https://github.com/pallets/jinja/blob/master/tests/test_imports.py#L122

      void testIncludes(Template template, Map<String, Object> context) {
        context['foo'] = 42;
        expect(template.renderMap(context), equals('[42|23]'));
      }

      template = env.fromString('{% include ["missing", "header"] %}');
      testIncludes(template, <String, Object>{});
      template = env.fromString('{% include x %}');
      testIncludes(template, <String, Object>{
        'x': <String>['missing', 'header'],
      });
      template = env.fromString('{% include [x, "header"] %}');
      testIncludes(template, <String, Object>{'x': 'missing'});
      template = env.fromString('{% include x %}');
      testIncludes(template, <String, Object>{'x': 'header'});
      template = env.fromString('{% include [x] %}');
      testIncludes(template, <String, Object>{'x': 'header'});
    });

    test('include ignore missing', () {
      Template template = env.fromString('{% include "missing" %}');
      expect(() => template.renderMap(), throwsA(isA<TemplateNotFound>()));

      for (String extra in <String>['', 'with context', 'without context']) {
        template =
            env.fromString('{% include "missing" ignore missing $extra %}');
        expect(template.renderMap(), equals(''));
      }
    });

    test('context include with overrides', () {
      final Environment env = Environment(
        loader: MapLoader(<String, String>{
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      final Template template = env.getTemplate('main');
      expect(template.renderMap(), equals('123'));
    });

    // TODO: добавить тест: unoptimized scopes
    // TODO: добавить тест: import from with context
  });
}
