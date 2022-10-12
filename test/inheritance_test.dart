import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

import 'package:jinja/src/utils.dart';

const String layout = '''
|{% block block1 %}1{% endblock %}
|{% block block2 %}2{% endblock %}
|{% block block3 %}
{% block block4 %}nested 4{% endblock %}
{% endblock %}|''';

const String level1 = '''
{% extends "layout" %}
{% block block1 %}1 level-1{% endblock %}''';

const String level2 = '''
{% extends "level1" %}
{% block block2 %}{% block block5 %}nested 5 level-2{%
endblock %}{% endblock %}''';

const String level3 = '''
{% extends "level2" %}
{% block block5 %}5 level-3{% endblock %}
{% block block4 %}4 level-3{% endblock %}''';

const String level4 = '''
{% extends "level3" %}
{% block block3 %}3 level-4{% endblock %}''';

const String working = '''
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const String doublee = '''
{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

void main() {
  group('Inheritance', () {
    var env = Environment(
      trimBlocks: true,
      loader: MapLoader({
        'layout': layout,
        'level1': level1,
        'level2': level2,
        'level3': level3,
        'level4': level4,
        'working': working,
        'doublee': doublee,
      }),
    );

    test('layout', () {
      var tmpl = env.getTemplate('layout');
      expect(tmpl.render(), equals('|1|2|nested 4|'));
    });

    test('level1', () {
      var tmpl = env.getTemplate('level1');
      expect(tmpl.render(), equals('|1 level-1|2|nested 4|'));
    });

    test('level2', () {
      var tmpl = env.getTemplate('level2');
      expect(tmpl.render(), equals('|1 level-1|nested 5 level-2|nested 4|'));
    });

    test('level3', () {
      var tmpl = env.getTemplate('level3');
      expect(tmpl.render(), equals('|1 level-1|5 level-3|4 level-3|'));
    });

    test('level4', () {
      var tmpl = env.getTemplate('level4');
      expect(tmpl.render(), equals('|1 level-1|5 level-3|3 level-4|'));
    });

    test('super', () {
      var env = Environment(
        loader: MapLoader({
          'a': '{% block intro %}INTRO{% endblock %}|'
              'BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ '
              'super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ '
              'super() }}--{% endblock %}\n{% block data '
              '%}[{{ super() }}]{% endblock %}',
        }),
      );

      var tmpl = env.getTemplate('c');
      expect(tmpl.render(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });

    test('working', () {
      expect(() => env.getTemplate('working'), returnsNormally);
    });

    test('reusing blocks', () {
      var tmpl = env.fromString(
          '{{ self.foo() }}|{% block foo %}42{% endblock %}|{{ self.foo() }}');
      expect(tmpl.render(), equals('42|42|42'));
    });

    test('preserve blocks', () {
      var env = Environment(
        loader: MapLoader({
          'a': '{% if false %}{% block x %}A{% endblock %}'
              '{% endif %}{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      var tmpl = env.getTemplate('b');
      expect(tmpl.render(), equals('BA'));
    });

    // not supported
    // test('dynamic inheritance', () {
    //   var env = Environment(
    //     loader: MapLoader({
    //       'default1': 'DEFAULT1{% block x %}{% endblock %}',
    //       'default2': 'DEFAULT2{% block x %}{% endblock %}',
    //       'child': '{% extends default %}{% block x %}CHILD{% endblock %}',
    //     }),
    //   );

    //   var tmpl = env.getTemplate('child');
    //   expect(tmpl.render({'default': 'default1'}), equals('DEFAULT1CHILD'));
    //   expect(tmpl.render({'default': 'default2'}), equals('DEFAULT2CHILD'));
    // });

    // not supported
    // test('multi inheritance', () {
    //   var env = Environment(
    //     loader: MapLoader({
    //       'default1': 'DEFAULT1{% block x %}{% endblock %}',
    //       'default2': 'DEFAULT2{% block x %}{% endblock %}',
    //       'child': '{% if default %}{% extends default %}{% else %}'
    //           '{% extends "default1" %}{% endif %}'
    //           '{% block x %}CHILD{% endblock %}',
    //     }),
    //   );

    //   var tmpl = env.getTemplate('child');
    //   expect(tmpl.render(), equals('DEFAULT1CHILD'));
    //   expect(tmpl.render({'default': 'default1'}), equals('DEFAULT1CHILD'));
    //   expect(tmpl.render({'default': 'default2'}), equals('DEFAULT2CHILD'));
    // });

    test('scoped block', () {
      var env = Environment(
        loader: MapLoader({
          'default.html': '{% for item in seq %}[{% block item scoped %}'
              '{% endblock %}]{% endfor %}'
        }),
      );

      var tmpl = env.fromString(
          '{% extends "default.html" %}{% block item %}{{ item }}{% endblock %}');
      expect(tmpl.render({'seq': range(5)}), equals('[0][1][2][3][4]'));
    });

    test('super in scoped block', () {
      var env = Environment(
        loader: MapLoader({
          'default.html': '{% for item in seq %}[{% block item scoped %}'
              '{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      var tmpl = env.fromString('{% extends "default.html" %}{% block item %}'
          '{{ super() }}|{{ item * 2 }}{% endblock %}');
      expect(
          tmpl.render({'seq': range(5)}), equals('[0|0][1|2][2|4][3|6][4|8]'));
    });

    // TODO: add test(import, from, macro): scoped block after inheritance
    // test('scoped block after inheritance', () {
    //   var env = Environment(
    //     loader: MapLoader({
    //       'layout.html': '''
    //         {% block useless %}{% endblock %}
    //         ''',
    //       'index.html': '''
    //         {%- extends 'layout.html' %}
    //         {% from 'helpers.html' import foo with context %}
    //         {% block useless %}
    //             {% for x in [1, 2, 3] %}
    //                 {% block testing scoped %}
    //                     {{ foo(x) }}
    //                 {% endblock %}
    //             {% endfor %}
    //         {% endblock %}
    //         ''',
    //       'helpers.html': '''
    //         {% macro foo(x) %}{{ the_foo + x }}{% endmacro %}
    //         ''',
    //     }),
    //   );

    //   var parts = const LineSplitter()
    //       .convert(env.getTemplate('index.html').render({'the_foo': 42}));
    //   expect(parts, orderedEquals(['43', '44', '45']));
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
          'default': '{% block x required %}{% endblock %}',
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
          'level1default1':
              '{% extends "default" %}{%- block x %}CHILD{% endblock %}',
          'level1default2':
              '{% extends "default2" %}{%- block x %}CHILD{% endblock %}',
          'level1default3':
              '{% extends "default3" %}{%- block x %}CHILD{% endblock %}'
        }),
      );

      var matcher = throwsA(predicate<TemplateSyntaxError>((error) =>
          error.message ==
          'required blocks can only contain comments or whitespace'));

      expect(() => env.getTemplate('level1default1').render(), matcher);
      expect(() => env.getTemplate('level1default2').render(), matcher);
      expect(() => env.getTemplate('level1default3').render(), matcher);
    });
  });
}
