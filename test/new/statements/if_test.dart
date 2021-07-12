import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('If', () {
    test('simple', () {
      expect(render('{% if true %}...{% endif %}'), equals('...'));
    });

    test('elif', () {
      expect(render('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}'''), equals('...'));
    });

    test('elif deep', () {
      final list = <String>[
        for (var i = 0; i < 999; i++) '{% elif a == ${i + 1} %}${i + 1}'
      ];
      final template =
          parse('{% if a == 0 %}0${list.join()}{% else %}x{% endif %}');
      expect(template.render({'a': 0}), equals('0'));
      expect(template.render({'a': 10}), equals('10'));
      expect(template.render({'a': 999}), equals('999'));
      expect(template.render({'a': 1000}), equals('x'));
    });

    test('else', () {
      expect(
          render('{% if false %}XXX{% else %}...{% endif %}'), equals('...'));
    });

    test('empty', () {
      expect(render('[{% if true %}{% else %}{% endif %}]'), equals('[]'));
    });

    test('complete', () {
      expect(
          render(
              '{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}',
              {'a': 0, 'b': false, 'c': 42, 'd': 42.0}),
          equals('C'));
    });

    test('no scope', () {
      expect(
          render(
              '{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}', {'a': true}),
          equals('1'));
      expect(render('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}'),
          equals('1'));
    });
  });
}
