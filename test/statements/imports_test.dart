import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  Environment env = Environment(
    globals: <String, Object>{'bar': 23},
    loader: MapLoader(<String, String>{
      // TODO: module
      // module: '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}'
      'header': '[{{ foo }}|{{ 23 }}]',
      'o_printer': '({{ o }})',
    }),
  );

  // TODO(test): imports

  group('include', () {
    Map<String, Object> foo42 = <String, Object>{'foo': 42};

    test('context include', () {
      Template template = env.fromString('{% include "header" %}');
      expect(template.render(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" with context %}');
      expect(template.render(foo42), equals('[42|23]'));

      template = env.fromString('{% include "header" without context %}');
      expect(template.render(foo42), equals('[|23]'));
    });

    test('choise includes', () {
      Template template = env.fromString('{% include ["missing", "header"] %}');
      expect(template.render(foo42), equals('[42|23]'));

      template = env
          .fromString('{% include ["missing", "missing2"] ignore missing %}');
      expect(template.render(foo42), equals(''));

      template = env.fromString('{% include ["missing", "missing2"] %}');
      expect(() => template.render(), throwsA(isA<TemplatesNotFound>()));

      // template names in error
      // https://github.com/pallets/jinja/blob/master/tests/test_imports.py#L122

      void testIncludes(Template template, Map<String, Object> context) {
        context['foo'] = 42;
        expect(template.render(context), equals('[42|23]'));
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
      expect(() => template.render(), throwsA(isA<TemplateNotFound>()));

      for (String extra in <String>['', 'with context', 'without context']) {
        template =
            env.fromString('{% include "missing" ignore missing $extra %}');
        expect(template.render(), equals(''));
      }
    });

    test('context include with overrides', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'main': "{% for item in [1, 2, 3] %}{% include 'item' %}{% endfor %}",
          'item': "{{ item }}",
        }),
      );

      Template template = env.getTemplate('main');
      expect(template.render(), equals('123'));
    });

    // TODO(test): unoptimized scopes
    // TODO(test): import from with context
  });
}
