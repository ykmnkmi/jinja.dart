@TestOn('vm')
library;

import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:test/test.dart';

void main() {
  var env = Environment(getAttribute: getAttribute);

  group('TryCatch', () {
    test('no error', () {
      var tmpl = env.fromString('{% try %}{{ 1 / 2 }}{% catch %}{% endtry %}');
      expect(tmpl.render(), equals('0.5'));
    });

    test('catch', () {
      var tmpl = env.fromString('''
          {%- try -%}
            {{ x | list }}
          {%- catch -%}
            collection expected
          {%- endtry %}''');
      expect(tmpl.render(), equals('collection expected'));
    });

    test('catch error', () {
      var tmpl = env.fromString('''
          {%- try -%}
            {{ x | list }}
          {%- catch error -%}
            {{ error | runtimetype }}
          {%- endtry %}''');
      expect(tmpl.render(), equals('TypeError'));
    });
  });
}
