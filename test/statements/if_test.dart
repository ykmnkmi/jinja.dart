import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('if', () {
    final env = Environment();

    test('simple', () {
      final template = env.fromString('{% if true %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('elif', () {
      final template = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(template.render(), equals('...'));
    });

    test('elif deep', () {
      final source = '{% if a == 0 %}0' +
          List.generate(999, (i) => '{% elif a == ${i + 1} %}${i + 1}').join() +
          '{% else %}x{% endif %}';
      final template = env.fromString(source);
      expect(template.renderWr(a: 0), equals('0'));
      expect(template.renderWr(a: 10), equals('10'));
      expect(template.renderWr(a: 999), equals('999'));
      expect(template.renderWr(a: 1000), equals('x'));
    });

    test('else', () {
      final template =
          env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('empty', () {
      final template = env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(template.render(), equals('[]'));
    });

    test('complete', () {
      final template =
          env.fromString('{% if a %}A{% elif b %}B{% elif c == d %}'
              'C{% else %}D{% endif %}');
      expect(template.renderWr(a: 0, b: false, c: 42, d: 42.0), equals('C'));
    });

    test('no scope', () {
      var template =
          env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.renderWr(a: true), equals('1'));
      template =
          env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render(), equals('1'));
    });
  });
}
