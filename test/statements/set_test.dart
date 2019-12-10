import 'package:jinja/jinja.dart';
import 'package:jinja/get_field.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('set', () {
    var envTrim = Environment(getField: getField, trimBlocks: true);

    test('simple', () {
      var template = envTrim.fromString('{% set foo = 1 %}{{ foo }}');
      expect(template.render(), equals('1'));
      // TODO: test module foo == 1
    });

    test('block', () {
      var template = envTrim.fromString('{% set foo %}42{% endset %}{{ foo }}');
      expect(template.render(), equals('42'));
      // TODO: test module foo == '42'
    });

    test('block escaping', () {
      var env = Environment(autoEscape: true);
      var template = env.fromString('{% set foo %}<em>{{ test }}</em>'
          '{% endset %}foo: {{ foo }}');
      expect(template.renderWr(test: '<unsafe>'), equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('set invalid', () {
      expect(() => envTrim.fromString('{% set foo["bar"] = 1 %}'), throwsA(isA<TemplateSyntaxError>()));

      var template = envTrim.fromString('{% set foo.bar = 1 %}');
      expect(() => template.renderWr(foo: <Object, Object>{}),
          throwsA(predicate<Object>((Object e) => e is TemplateRuntimeError && e.message == 'non-namespace object')));
    });

    test('namespace redefined', () {
      var template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar = "hi" %}');
      expect(() => template.renderWr(namespace: () => <Object, Object>{}),
          throwsA(predicate<Object>((Object e) => e is TemplateRuntimeError && e.message == 'non-namespace object')));
    });

    test('namespace', () {
      var template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar = "42" %}'
          '{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('namespace block', () {
      var template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar %}42{% endset %}'
          '{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('init namespace', () {
      var template = envTrim.fromString('{% set ns = namespace(d, self=37) %}'
          '{% set ns.b = 42 %}'
          '{{ ns.a }}|{{ ns.self }}|{{ ns.b }}');
      expect(template.renderWr(d: <String, Object>{'a': 13}), equals('13|37|42'));
    });

    test('namespace loop', () {
      var template = envTrim.fromString('{% set ns = namespace(found=false) %}'
          '{% for x in range(4) %}'
          '{% if x == v %}'
          '{% set ns.found = true %}'
          '{% endif %}'
          '{% endfor %}'
          '{{ ns.found }}');
      expect(template.renderWr(v: 3), equals('true'));
      expect(template.renderWr(v: 4), equals('false'));
    });

    // TODO: test namespace macro

    test('block escapeing filtered', () {
      var env = Environment(autoEscape: true);
      var template = env.fromString('{% set foo | trim %}<em>{{ test }}</em>    '
          '{% endset %}foo: {{ foo }}');
      expect(template.renderWr(test: '<unsafe>'), equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('block filtered', () {
      var template = envTrim.fromString('{% set foo | trim | length | string %} 42    {% endset %}'
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
      var template = envTrim.fromString('{% set a = " xxx " %}'
          '{% set foo | myfilter(a) | trim | length | string %}'
          ' {% set b = " yy " %} 42 {{ a }}{{ b }}   '
          '{% endset %}'
          '{{ foo }}');
      expect(template.render(), equals('11'));
      // TODO: test module foo == '11'
    });
  });
}
