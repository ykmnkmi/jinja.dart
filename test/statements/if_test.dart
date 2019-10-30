import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('if', () {
    Environment env = Environment();

    test('simple', () {
      Template template = env.fromString('{% if true %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('elif', () {
      Template template = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(template.render(), equals('...'));
    });

    test('elif deep', () {
      String source = '{% if a == 0 %}0' +
          List<String>.generate(
              999, (int i) => '{% elif a == ${i + 1} %}${i + 1}').join() +
          '{% else %}x{% endif %}';
      Template template = env.fromString(source);
      expect(template.render(<String, Object>{'a': 0}), equals('0'));
      expect(template.render(<String, Object>{'a': 10}), equals('10'));
      expect(template.render(<String, Object>{'a': 999}), equals('999'));
      expect(template.render(<String, Object>{'a': 1000}), equals('x'));
    });

    test('else', () {
      Template template =
          env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('empty', () {
      Template template =
          env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(template.render(), equals('[]'));
    });

    test('complete', () {
      Template template =
          env.fromString('{% if a %}A{% elif b %}B{% elif c == d %}'
              'C{% else %}D{% endif %}');
      expect(
          template
              .render(<String, Object>{'a': 0, 'b': false, 'c': 42, 'd': 42.0}),
          equals('C'));
    });

    test('no scope', () {
      Template template =
          env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render(<String, Object>{'a': true}), equals('1'));
      template =
          env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render(), equals('1'));
    });
  });
}
