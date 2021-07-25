import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('If', () {
    test('simple', () {
      final tmpl = env.fromString('{% if true %}...{% endif %}');
      expect(tmpl.renderMap(), equals('...'));
    });

    test('elif', () {
      final tmpl = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(tmpl.renderMap(), equals('...'));
    });

    test('elif deep', () {
      final elifs = <String>[
        for (var i = 1; i < 1000; i++) '{% elif a == $i %}$i'
      ].join();
      final tmpl =
          env.fromString('{% if a == 0 %}0$elifs{% else %}x{% endif %}');
      expect(tmpl.renderMap({'a': 0}), equals('0'));
      expect(tmpl.renderMap({'a': 10}), equals('10'));
      expect(tmpl.renderMap({'a': 999}), equals('999'));
      expect(tmpl.renderMap({'a': 1000}), equals('x'));
    });

    test('else', () {
      final tmpl = env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(tmpl.renderMap(), equals('...'));
    });

    test('empty', () {
      final tmpl = env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(tmpl.renderMap(), equals('[]'));
    });

    test('complete', () {
      final tmpl = env.fromString(
          '{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}');
      expect(
          tmpl.renderMap({'a': 0, 'b': false, 'c': 42, 'd': 42.0}), equals('C'));
    });

    test('no scope', () {
      var tmpl =
          env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.renderMap({'a': true}), equals('1'));
      tmpl =
          env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.renderMap(), equals('1'));
    });
  });
}
