import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/utils.dart';
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

const String doubleextends = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

void main() {
  group('inheritance', () {
    Environment env = Environment(
      loader: MapLoader(<String, String>{
        'layout': layout,
        'level1': level1,
        'level2': level2,
        'level3': level3,
        'level4': level4,
        'working': working,
      }),
      trimBlocks: true,
    );

    test('layout', () {
      Template template = env.getTemplate('layout');
      expect(
          template.render(),
          equals('|block 1 from layout|block 2 from '
              'layout|nested block 4 from layout|'));
    });

    test('level1', () {
      Template template = env.getTemplate('level1');
      expect(
          template.render(),
          equals('|block 1 from level1|block 2 from '
              'layout|nested block 4 from layout|'));
    });

    test('level2', () {
      Template template = env.getTemplate('level2');
      expect(
          template.render(),
          equals('|block 1 from level1|nested block 5 from '
              'level2|nested block 4 from layout|'));
    });

    test('level3', () {
      Template template = env.getTemplate('level3');
      expect(
          template.render(),
          equals('|block 1 from level1|block 5 from level3|'
              'block 4 from level3|'));
    });

    test('level4', () {
      Template template = env.getTemplate('level4');
      expect(
          template.render(),
          equals('|block 1 from level1|block 5 from '
              'level3|block 3 from level4|'));
    });

    test('super', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'a': '{% block intro %}INTRO{% endblock %}|'
              'BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ '
              'super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ '
              'super() }}--{% endblock %}\n{% block data '
              '%}[{{ super() }}]{% endblock %}',
        }),
      );

      Template template = env.getTemplate('c');
      expect(template.render(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });

    test('working', () {
      Template template = env.getTemplate('working');
      expect(template, isNotNull);
    });

    test('reuse blocks', () {
      Template template = env.fromString('{{ self.foo() }}|{% block foo %}42'
          '{% endblock %}|{{ self.foo() }}');
      expect(template.render(), equals('42|42|42'));
    });

    test('preserve blocks', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'a': '{% if false %}{% block x %}A{% endblock %}'
              '{% endif %}{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      Template template = env.getTemplate('b');
      expect(template.render(), equals('BA'));
    });

    test('dynamic inheritance', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'master1': 'MASTER1{% block x %}{% endblock %}',
          'master2': 'MASTER2{% block x %}{% endblock %}',
          'child': '{% extends master %}{% block x %}CHILD{% endblock %}',
        }),
      );

      Template template = env.getTemplate('child');

      for (int i in <int>[1, 2]) {
        expect(template.render(<String, Object>{'master': 'master$i'}),
            equals('MASTER${i}CHILD'));
      }
    });

    test('multi inheritance', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'master1': 'MASTER1{% block x %}{% endblock %}',
          'master2': 'MASTER2{% block x %}{% endblock %}',
          'child': '''{% if master %}{% extends master %}{% else %}{% extends
                'master1' %}{% endif %}{% block x %}CHILD{% endblock %}''',
        }),
      );

      Template template = env.getTemplate('child');
      expect(template.render(<String, Object>{'master': 'master1'}),
          equals('MASTER1CHILD'));
      expect(template.render(<String, Object>{'master': 'master2'}),
          equals('MASTER2CHILD'));
      expect(template.render(), equals('MASTER1CHILD'));
    });

    test('scoped block', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'master.html': '{% for item in seq %}[{% block item scoped %}'
              '{% endblock %}]{% endfor %}',
        }),
      );

      Template template =
          env.fromString('{% extends "master.html" %}{% block item %}'
              '{{ item }}{% endblock %}');
      expect(template.render(<String, Object>{'seq': range(5)}),
          equals('[0][1][2][3][4]'));
    });

    test('super in scoped block', () {
      Environment env = Environment(
        loader: MapLoader(<String, String>{
          'master.html': '{% for item in seq %}[{% block item scoped %}'
              '{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      Template template =
          env.fromString('{% extends "master.html" %}{% block item %}'
              '{{ super() }}|{{ item * 2 }}{% endblock %}');
      expect(template.render(<String, Object>{'seq': range(5)}),
          equals('[0|0][1|2][2|4][3|6][4|8]'));
    });

    // TODO: test scoped block after inheritance
    // TODO: test fixed macro scoping bug

    test('double extends', () {
      expect(() => Template(doubleextends),
          throwsA(predicate<Object>((Object e) => e is TemplateError)));
    });
  });
}
