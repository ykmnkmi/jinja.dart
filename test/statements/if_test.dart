import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('if', () {
    var env = Environment();

    test('simple', () {
      var template = env.fromString('{% if true %}...{% endif %}');
      expect(template.renderMap(), equals('...'));
    });

    test('elif', () {
      var template = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(template.renderMap(), equals('...'));
    });

    test('elif deep', () {
      var source = '{% if a == 0 %}0' +
          List<String>.generate(999, (int i) => '{% elif a == ${i + 1} %}${i + 1}').join() +
          '{% else %}x{% endif %}';
      var template = env.fromString(source);
      expect(template.render(a: 0), equals('0'));
      expect(template.render(a: 10), equals('10'));
      expect(template.render(a: 999), equals('999'));
      expect(template.render(a: 1000), equals('x'));
    });

    test('else', () {
      var template = env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(template.renderMap(), equals('...'));
    });

    test('empty', () {
      var template = env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(template.renderMap(), equals('[]'));
    });

    test('complete', () {
      var template = env.fromString('{% if a %}A{% elif b %}B{% elif c == d %}'
          'C{% else %}D{% endif %}');
      expect(template.render(a: 0, b: false, c: 42, d: 42.0), equals('C'));
    });

    test('no scope', () {
      var template = env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render(a: true), equals('1'));
      template = env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.renderMap(), equals('1'));
    });
  });
}
