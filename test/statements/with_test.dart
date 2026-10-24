@TestOn('vm || chrome')
library;

import 'dart:convert';

import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  var env = Environment();

  group('With', () {
    test('with', () {
      var tmpl = env.fromString('''
        {% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''');

      var lines = const LineSplitter()
          .convert(tmpl.render({'a': 1, 'b': 2}))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty);
      expect(lines, orderedEquals(<String>['42 = 23', '1 = 2']));
    });

    test('with argument scoping', () {
      var tmpl = env.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith %}''');
      expect(tmpl.render({'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });

  group('With extra', () {
    test('with tuple unpacking', () {
      var tmpl = env.fromString('''
        {%- with (a, b) = [1, 2], c = 3 -%}
            {{ a }}|{{ b }}|{{ c }}
        {%- endwith %}''');
      expect(tmpl.render(), equals('1|2|3'));
    });
  });
}
