import 'dart:convert';

import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('With', () {
    test('with', () {
      final tmpl = env.fromString('''
        {% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}
        ''');

      final lines = const LineSplitter()
          .convert(tmpl.render({'a': 1, 'b': 2}))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty);
      expect(lines, orderedEquals(<String>['42 = 23', '1 = 2']));
    });

    test('with argument scoping', () {
      final tmpl = env.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}
        ''');
      expect(tmpl.render({'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });
}
