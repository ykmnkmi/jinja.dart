import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('set', () {
    final env = Environment(trimBlocks: true);

    test('simple', () {
      final template = env.fromSource('{% set foo = 1 %}{{ foo }}');
      expect(template.render(), equals('1'));
      // TODO: test module foo == 1
    });

    test('block', () {
      final template = env.fromSource('{% set foo %}42{% endset %}{{ foo }}');
      expect(template.render(), equals('42'));
      // TODO: test module foo == '42'
    });
  });
}
