import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Slices test', () {
    test('sitems from the beginning through stop-1', () {
      var environment = Environment();
      var tmpl = environment
          .fromString('{% set foo = [0, 1, 2, 3, 4] %}{{ foo[:2] }}');
      expect(tmpl.render(), equals('[0, 1]'));
    });
    test('items start through the rest of the array', () {
      var environment = Environment();
      var tmpl = environment
          .fromString('{% set foo = [0, 1, 2, 3, 4] %}{{ foo[2:] }}');
      expect(tmpl.render(), equals('[2, 3, 4]'));
    });
    test('items start through stop-1', () {
      var environment = Environment();
      var tmpl = environment
          .fromString('{% set foo = [0, 1, 2, 3, 4] %}{{ foo[2:3] }}');
      expect(tmpl.render(), equals('[2]'));
    });
  });
}
