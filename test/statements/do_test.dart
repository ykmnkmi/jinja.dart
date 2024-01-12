import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('Do', () {
    test('do', () {
      var tmpl = env.fromString('''
            {%- set items = [] %}
            {%- for char in "foo" %}
                {%- do items.add(loop.index0 ~ char) %}
            {%- endfor %}{{ items|join(', ') }}''');
      expect(tmpl.render(), equals('0f, 1o, 2o'));
    });
  });
}
