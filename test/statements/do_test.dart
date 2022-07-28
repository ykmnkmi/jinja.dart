import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:test/test.dart';

void main() {
  group('Do', () {
    test('do', () {
      var env = Environment(getAttribute: getAttribute);
      var tmpl = env.fromString('''
            {%- set items = [] %}
            {%- for char in "foo" %}
                {%- do items.add(loop.index0 ~ char) %}
            {%- endfor %}{{ items|join(', ') }}''');
      expect(tmpl.render(), equals('0f, 1o, 2o'));
    });
  });
}
