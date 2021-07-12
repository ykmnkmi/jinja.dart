import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

const String layout = '''|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|''';

const String level1 = '''{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}''';

const String level2 = '''{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}''';

const String level3 = '''{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}''';

const String level4 = '''{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}''';

const String working = '''{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const String doublee = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const Map<String, String> mapping = <String, String>{
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
    late final environment =
        Environment(loader: MapLoader(mapping), trimBlocks: true);

    String renderByName(String name, [Map<String, Object?>? data]) {
      return environment.getTemplate(name).render(data);
    }

    test('layout', () {
      final result = renderByName('layout');
      expect(
          result,
          equals(
              '|block 1 from layout|block 2 from layout|nested block 4 from layout|'));
    });

    test('level1', () {
      final result = renderByName('level1');
      expect(
          result,
          equals(
              '|block 1 from level1|block 2 from layout|nested block 4 from layout|'));
    });

    test('level2', () {
      final result = renderByName('level2');
      expect(
          result,
          equals(
              '|block 1 from level1|nested block 5 from level2|nested block 4 from layout|'));
    });

    test('level3', () {
      final result = renderByName('level3');
      expect(
          result,
          equals(
              '|block 1 from level1|block 5 from level3|block 4 from level3|'));
    });

    test('level4', () {
      final result = renderByName('level4');
      expect(
          result,
          equals(
              '|block 1 from level1|block 5 from level3|block 3 from level4|'));
    });

    test('super', () {
      final environment = Environment(
        loader: MapLoader({
          'a':
              '{% block intro %}INTRO{% endblock %}|BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ super() }}){% endblock %}',
          'c':
              '{% extends "b" %}{% block intro %}--{{ super() }}--{% endblock %}\n{% block data %}[{{ super() }}]'
                  '{% endblock %}',
        }),
      );

      expect(environment.getTemplate('c').render(),
          equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });

    test('working', () {
      expect(renderByName('working'), isNotNull);
    });

    test('reusing blocks', () {
      final template = environment.fromString(
          '{{ self.foo() }}|{% block foo %}42{% endblock %}|{{ self.foo() }}');
      expect(template.render(), equals('42|42|42'));
    });

    test('preserve blocks', () {
      final environment = Environment(
        loader: MapLoader({
          'a':
              '{% if false %}{% block x %}A{% endblock %}{% endif %}{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      expect(environment.getTemplate('b').render(), equals('BA'));
    });

    test('scoped block', () {
      final environment = Environment(
        loader: MapLoader({
          'default.html':
              '{% for item in seq %}[{% block item scoped %}{% endblock %}]{% endfor %}',
        }),
      );

      final source =
          '{% extends "default.html" %}{% block item %}{{ item }}{% endblock %}';
      expect(environment.fromString(source).render({'seq': range(5)}),
          equals('[0][1][2][3][4]'));
    });

    test('super in scoped block', () {
      final environment = Environment(
        loader: MapLoader({
          'default.html':
              '{% for item in seq %}[{% block item scoped %}{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      final template = environment.fromString(
          '{% extends "default.html" %}{% block item %}{{ super() }}|{{ item * 2 }}{% endblock %}');
      expect(template.render({'seq': range(5)}),
          equals('[0|0][1|2][2|4][3|6][4|8]'));
    });

    // TODO: after macro: enable test
    test('scoped block after inheritance', () {
      final environment = Environment(
        loader: MapLoader({
          'layout.html': '{% block useless %}{% endblock %}',
          'index.html': '''
            {%- extends 'layout.html' %}
            {% from 'helpers.html' import foo with context %}
            {% block useless %}
                {% for x in [1, 2, 3] %}
                    {% block testing scoped %}
                        {{ foo(x) }}
                    {% endblock %}
                {% endfor %}
            {% endblock %}''',
          'helpers.html': '{% macro foo(x) %}{{ the_foo + x }}{% endmacro %}',
        }),
      );

      final iterable = environment
          .getTemplate('index.html')
          .render({'the_foo': 42})
          .split(RegExp('\\s+'))
          .where((part) => part.isNotEmpty);
      expect(iterable, orderedEquals(<String>['43', '44', '45']));
    }, skip: true);
  });

  test('level1 required', () {
    final environment = Environment(
      loader: MapLoader({
        'default': '{% block x required %}{# comment #}\n {% endblock %}',
        'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
      }),
    );

    expect(environment.getTemplate('level1').render(), equals('[1]'));
  });

  test('level2 required', () {
    final environment = Environment(
      loader: MapLoader({
        'default': "{% block x required %}{% endblock %}",
        'level1': '{% extends "default" %}{% block x %}[1]{% endblock %}',
        'level2': '{% extends "default" %}{% block x %}[2]{% endblock %}',
      }),
    );

    expect(environment.getTemplate('level1').render(), equals('[1]'));
    expect(environment.getTemplate('level2').render(), equals('[2]'));
  });

  test('level3 required', () {
    final environment = Environment(
      loader: MapLoader({
        'default': '{% block x required %}{% endblock %}',
        'level1': '{% extends "default" %}',
        'level2': '{% extends "level1" %}{% block x %}[2]{% endblock %}',
        'level3': '{% extends "level2" %}',
      }),
    );

    bool matcher(TemplateSyntaxError error) {
      return error.message == 'required block \'x\' not found';
    }

    expect(() => environment.getTemplate('level1').render(),
        throwsA(predicate<TemplateSyntaxError>(matcher)));
    expect(environment.getTemplate('level2').render(), equals('[2]'));
    expect(environment.getTemplate('level3').render(), equals('[2]'));
  });

  test('invalid required', () {
    final environment = Environment(
      loader: MapLoader({
        'default': '{% block x required %}data {# #}{% endblock %}',
        'default2':
            '{% block x required %}{% block y %}{% endblock %}  {% endblock %}',
        'default3': '{% block x required %}{% if true %}{% endif %}  '
            '{% endblock %}',
        "level1default":
            '{% extends "default" %}{%- block x %}CHILD{% endblock %}',
        "level1default2":
            '{% extends "default2" %}{%- block x %}CHILD{% endblock %}',
        "level1default3":
            '{% extends "default3" %}{%- block x %}CHILD{% endblock %}',
      }),
    );

    bool matcher(TemplateSyntaxError error) {
      return error.message ==
          'required blocks can only contain comments or whitespace';
    }

    expect(() => environment.getTemplate('level1default').render(),
        throwsA(predicate<TemplateSyntaxError>(matcher)));
    expect(() => environment.getTemplate('level1default2').render(),
        throwsA(predicate<TemplateSyntaxError>(matcher)));
    expect(() => environment.getTemplate('level1default3').render(),
        throwsA(predicate<TemplateSyntaxError>(matcher)));
  });
}
