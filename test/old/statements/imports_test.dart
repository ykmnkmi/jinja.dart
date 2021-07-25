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
