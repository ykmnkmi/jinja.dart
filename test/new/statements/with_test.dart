import 'dart:convert';

import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('With', () {
    test('with', () {
      final source = '''{% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''';

      final lines = const LineSplitter()
          .convert(render(source, {'a': 1, 'b': 2}))
          .map((line) => line.trim())
          .toList();
      expect(lines[0], equals('42 = 23'));
      expect(lines[1], equals('1 = 2'));
    });

    test('with argument scoping', () {
      final source = '''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}''';
      expect(render(source, {'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });
}
