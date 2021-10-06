import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

const layout = '''|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|''';

const level1 = '''{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}''';

const level2 = '''{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}''';

const level3 = '''{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}''';

const level4 = '''{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}''';

const working = '''{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const doublee = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const mapping = <String, String>{
  'layout': layout,
  'level1': level1,
  'level2': level2,
  'level3': level3,
  'level4': level4,
  'working': working,
  'doublee': doublee,
};

void main() {
  group('Inheritance', () {
    var env = Environment(loader: MapLoader(mapping), trimBlocks: true);

    test('layout', () {
      var match = '|block 1 from layout|block 2 from layout|'
          'nested block 4 from layout|';
      expect(env.getTemplate('layout').render(), equals(match));
    });

    test('level1', () {
      var match = '|block 1 from level1|block 2 from layout|'
          'nested block 4 from layout|';
      expect(env.getTemplate('level1').render(), equals(match));
    });

    test('level2', () {
      var match = '|block 1 from level1|nested block 5 from level2|'
          'nested block 4 from layout|';
      expect(env.getTemplate('level2').render(), equals(match));
    });

    test('level3', () {
      var match =
          '|block 1 from level1|block 5 from level3|block 4 from level3|';
      expect(env.getTemplate('level3').render(), equals(match));
    });

    test('level4', () {
      var match =
          '|block 1 from level1|block 5 from level3|block 3 from level4|';
      expect(env.getTemplate('level4').render(), equals(match));
    });

    test('super', () {
      var env = Environment(
        loader: MapLoader({
          'a': '{% block intro %}INTRO{% endblock %}|BEFORE|{% block data %}'
              'INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ super() }}--'
              '{% endblock %}\n{% block data %}[{{ super() }}]{% endblock %}',
        }),
      );

      var tmpl = env.getTemplate('c');
      expect(tmpl.render(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });

    test('working', () {
      expect(env.getTemplate('working').render(), isNotNull);
    });

    test('reusing blocks', () {
      var tmpl = env.fromString('{{ self.foo() }}|{% block foo %}42'
          '{% endblock %}|{{ self.foo() }}');
      expect(tmpl.render(), equals('42|42|42'));
    });

    test('preserve blocks', () {
      var env = Environment(
        loader: MapLoader({
          'a': '{% if false %}{% block x %}A{% endblock %}{% endif %}'
              '{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      expect(env.getTemplate('b').render(), equals('BA'));
    });

    test('scoped block', () {
      var env = Environment(
        loader: MapLoader({
          'default.html': '{% for item in seq %}[{% block item scoped %}'
              '{% endblock %}]{% endfor %}',
        }),
      );

      var tmpl = env.fromString('{% extends "default.html" %}{% block item %}'
          '{{ item }}{% endblock %}');
      expect(tmpl.render({'seq': range(5)}), equals('[0][1][2][3][4]'));
    });

    test('super in scoped block', () {
      var env = Environment(
        loader: MapLoader({
          'default.html': '{% for item in seq %}[{% block item scoped %}'
              '{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      var tmpl = env.fromString('{% extends "default.html" %}'
          '{% block item %}{{ super() }}|{{ item * 2 }}{% endblock %}');
      var result = tmpl.render({'seq': range(5)});
      expect(result, equals('[0|0][1|2][2|4][3|6][4|8]'));
    });

    // TODO: after macro: enable test
    // test('scoped block after inheritance', () {
    //   var env = Environment(
    //     loader: MapLoader({
    //       'layout.html': '{% block useless %}{% endblock %}',
    //       'index.html': '''
    //         {%- extends 'layout.html' %}
    //         {% from 'helpers.html' import foo with context %}
    //         {% block useless %}
    //             {% for x in [1, 2, 3] %}
    //                 {% block testing scoped %}
    //                     {{ foo(x) }}
    //                 {% endblock %}
    //             {% endfor %}
    //         {% endblock %}''',
    //       'helpers.html': '{% macro foo(x) %}{{ the_foo + x }}{% endmacro %}',
    //     }),
    //   );

    //   var iterable = environment
    //       .getTemplate('index.html')
    //       .render({'the_foo': 42})
    //       .split(RegExp('\\s+'))
    //       .where((part) => part.isNotEmpty);
    //   expect(iterable, orderedEquals(<String>['43', '44', '45']));
    // });

    test('level1 required', () {
      var env = Environment(
        loader: MapLoader({
          'default': '{% block x required %}{# comment #}\n {% endblock %}',
          'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
        }),
      );

      expect(env.getTemplate('level1').render(), equals('[1]'));
    });

    test('level2 required', () {
      var env = Environment(
        loader: MapLoader({
          'default': "{% block x required %}{% endblock %}",
          'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
          'level2': '{% extends "default" %}{% block x %}[2]{% endblock %}',
        }),
      );

      expect(env.getTemplate('level1').render(), equals('[1]'));
      expect(env.getTemplate('level2').render(), equals('[2]'));
    });

    test('level3 required', () {
      var env = Environment(
        loader: MapLoader({
          'default': '{% block x required %}{% endblock %}',
          'level1': '{% extends "default" %}',
          'level2': '{% extends "level1" %}{% block x %}[2]{% endblock %}',
          'level3': '{% extends "level2" %}',
        }),
      );

      expect(
          () => env.getTemplate('level1').render(),
          throwsA(predicate<TemplateRuntimeError>(
              (error) => error.message == 'required block \'x\' not found')));
      expect(env.getTemplate('level2').render(), equals('[2]'));
      expect(env.getTemplate('level3').render(), equals('[2]'));
    });

    test('invalid required', () {
      var env = Environment(
          loader: MapLoader({
        'default': '{% block x required %}data {# #}{% endblock %}',
        'default2': '{% block x required %}{% block y %}'
            '{% endblock %}  {% endblock %}',
        'default3': '{% block x required %}{% if true %}{% endif %}  '
            '{% endblock %}',
        "level1default":
            '{% extends "default" %}{%- block x %}CHILD{% endblock %}',
        "level1default2":
            '{% extends "default2" %}{%- block x %}CHILD{% endblock %}',
        "level1default3":
            '{% extends "default3" %}{%- block x %}CHILD{% endblock %}'
      }));
      var matcher = throwsA(predicate<TemplateSyntaxError>((error) =>
          error.message ==
          'required blocks can only contain comments or whitespace'));
      expect(() => env.getTemplate('level1default').render(), matcher);
      expect(() => env.getTemplate('level1default2').render(), matcher);
      expect(() => env.getTemplate('level1default3').render(), matcher);
    });
  });
}
