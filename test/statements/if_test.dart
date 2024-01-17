@TestOn('vm || chrome')
library;

import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  var env = Environment();

  group('If', () {
    test('simple', () {
      var tmpl = env.fromString('{% if true %}...{% endif %}');
      expect(tmpl.render(), equals('...'));
    });

    test('elif', () {
      var tmpl = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(tmpl.render(), equals('...'));
    });

    test('elif deep', () {
      var buffer = StringBuffer('{% if a == 0 %}0');

      for (var i = 1; i < 1000; i++) {
        buffer.write('{% elif a == $i %}$i');
      }

      buffer.write('{% else %}x{% endif %}');

      var tmpl = env.fromString('$buffer');
      expect(tmpl.render({'a': 0}), equals('0'));
      expect(tmpl.render({'a': 10}), equals('10'));
      expect(tmpl.render({'a': 999}), equals('999'));
      expect(tmpl.render({'a': 1000}), equals('x'));
    });

    test('else', () {
      var tmpl = env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(tmpl.render(), equals('...'));
    });

    test('empty', () {
      var tmpl = env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(tmpl.render(), equals('[]'));
    });

    test('complete', () {
      var tmpl = env.fromString(
          '{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}');
      expect(
          tmpl.render({'a': 0, 'b': false, 'c': 42, 'd': 42.0}), equals('C'));
    });

    test('no scope', () {
      var tmpl =
          env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.render({'a': true}), equals('1'));
      tmpl =
          env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.render(), equals('1'));
    });
  });
}
