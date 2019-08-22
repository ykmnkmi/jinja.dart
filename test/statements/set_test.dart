import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('set', () {
    final envTrim = Environment(trimBlocks: true);

    test('simple', () {
      final template = envTrim.fromSource('{% set foo = 1 %}{{ foo }}');
      expect(template.render(), equals('1'));
      // TODO: test module foo == 1
    });

    test('block', () {
      final template =
          envTrim.fromSource('{% set foo %}42{% endset %}{{ foo }}');
      expect(template.render(), equals('42'));
      // TODO: test module foo == '42'
    });

    test('block escaping', () {
      final env = Environment(autoEscape: true);
      final template = env.fromSource('{% set foo %}<em>{{ test }}</em>'
          '{% endset %}foo: {{ foo }}');
      expect(template.renderWr(test: '<unsafe>'),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    // TODO: test set invalid
    // TODO: test namespace redefined

    test('namespace', () {
      final template = envTrim.fromSource('{% set ns = namespace() %}'
          '{% set ns.bar = "42" %}'
          '{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('namespace block', () {
      final template = envTrim.fromSource('{% set ns = namespace() %}'
          '{% set ns.bar %}42{% endset %}'
          '{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('init namespace', () {
      final template = envTrim.fromSource('{% set ns = namespace(d, self=37) %}'
          '{% set ns.b = 42 %}'
          '{{ ns.a }}|{{ ns.self }}|{{ ns.b }}');
      expect(template.renderWr(d: {'a': 13}), equals('13|37|42'));
    });

    test('namespace loop', () {
      final template =
          envTrim.fromSource('{% set ns = namespace(found=false) %}'
              '{% for x in range(4) %}'
              '{% if x == v %}'
              '{% set ns.found = true %}'
              '{% endif %}'
              '{% endfor %}'
              '{{ ns.found }}');
      expect(template.renderWr(v: 3), equals('true'));
      expect(template.renderWr(v: 4), equals('false'));
    });

    // TODO: test namespace redefined

    test('block escapeing filtered', () {
      final env = Environment(autoEscape: true);
      final template =
          env.fromSource('{% set foo | trim %}<em>{{ test }}</em>    '
              '{% endset %}foo: {{ foo }}');
      expect(template.renderWr(test: '<unsafe>'),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('block filtered', () {
      final template = envTrim.fromSource(
          '{% set foo | trim | length | string %} 42    {% endset %}'
          '{{ foo }}');
      expect(template.render(), equals('2'));
      // TODO: test module foo == '2'
    });

    test('block filtered set', () {
      dynamic myfilter(Object value, Object arg) {
        assert(arg == ' xxx ');
        return value;
      }

      envTrim.filters['myfilter'] = myfilter;
      final template = envTrim.fromSource('{% set a = " xxx " %}'
          '{% set foo | myfilter(a) | trim | length | string %}'
          ' {% set b = " yy " %} 42 {{ a }}{{ b }}   '
          '{% endset %}'
          '{{ foo }}');
      expect(template.render(), equals('11'));
      // TODO: test module foo == '11'
    });
  });
}
