import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:test/test.dart';

const emptyMap = <Object?, Object?>{};

void main() {
  group('Set', () {
    test('normal', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('{% set foo = 1 %}{{ foo }}');
      expect(tmpl.render(), equals('1'));
    });

    test('block', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('{% set foo %}42{% endset %}{{ foo }}');
      expect(tmpl.render(), equals('42'));
    });

    test('block escaping', () {
      var env = Environment(autoEscape: true);
      var tmpl = env.fromString(
          '{% set foo %}<em>{{ test }}</em>{% endset %}foo: {{ foo }}');
      expect(tmpl.render({'test': '<unsafe>'}),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('set invalid', () {
      var env = Environment(trimBlocks: true);
      expect(() => env.fromString('{% set foo["bar"] = 1 %}'),
          throwsA(isA<TemplateSyntaxError>()));
      var tmpl = env.fromString('{% set foo.bar = 1 %}');
      expect(
          () => tmpl.render({'foo': emptyMap}),
          throwsA(predicate<TemplateRuntimeError>(
              (error) => error.message == 'non-namespace object')));
    });

    test('namespace redefined', () {
      var env = Environment(trimBlocks: true);
      var tmpl =
          env.fromString('{% set ns = namespace() %}{% set ns.bar = "hi" %}');
      expect(
          () => tmpl.render({'namespace': () => emptyMap}),
          throwsA(predicate<TemplateRuntimeError>(
              (error) => error.message == 'non-namespace object')));
    });

    test('namespace', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString(
          '{% set ns = namespace() %}{% set ns.bar = "42" %}{{ ns.bar }}');
      expect(tmpl.render(), equals('42'));
    });

    test('namespace block', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString(
          '{% set ns = namespace() %}{% set ns.bar %}42{% endset %}{{ ns.bar }}');
      expect(tmpl.render(), equals('42'));
    });

    test('init namespace', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('{% set ns = namespace(d, self=37) %}'
          '{% set ns.b = 42 %}'
          '{{ ns.a }}|{{ ns.self }}|{{ ns.b }}');
      expect(
          tmpl.render({
            'd': {'a': 13}
          }),
          equals('13|37|42'));
    });

    test('namespace loop', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('{% set ns = namespace(found=false) %}'
          '{% for x in range(4) %}'
          '{% if x == v %}'
          '{% set ns.found = true %}'
          '{% endif %}'
          '{% endfor %}'
          '{{ ns.found }}');
      expect(tmpl.render({'v': 3}), equals('true'));
      expect(tmpl.render({'v': 4}), equals('false'));
    });

    // TODO: add test: namespace macro

    test('block escapeing filtered', () {
      var env = Environment(autoEscape: true);
      var tmpl = env.fromString(
          '{% set foo | trim %}<em>{{ test }}</em>    {% endset %}foo: {{ foo }}');
      expect(tmpl.render({'test': '<unsafe>'}),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('block filtered', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString(
          '{% set foo | trim | length | string %} 42    {% endset %}{{ foo }}');
      expect(tmpl.render(), equals('2'));
    });

    test('block filtered set', () {
      Object? myfilter(Object? value, Object? arg) {
        assert(arg == ' xxx ');
        return value;
      }

      var env = Environment(
          filters: {'myfilter': myfilter},
          getAttribute: getAttribute,
          trimBlocks: true);
      var tmpl = env.fromString('{% set a = " xxx " %}'
          '{% set foo | myfilter(a) | trim | length | string %}'
          ' {% set b = " yy " %} 42 {{ a }}{{ b }}   '
          '{% endset %}'
          '{{ foo }}');
      expect(tmpl.render(), equals('11'));
    });
  });
}
