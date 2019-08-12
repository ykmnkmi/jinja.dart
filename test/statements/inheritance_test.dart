import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

var layout = '''|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|''';

var level1 = '''{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}''';

var level2 = '''{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}''';

var level3 = '''{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}''';

var level4 = '''{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}''';

var working = '''{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

var doubleextends = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

void main() {
  final env = Environment(
    loader: MapLoader({
      'layout': layout,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
      'working': working,
      'doublee': doubleextends,
    }),
    trimBlocks: true,
  );

  test('layout', () {
    final template = env.getTemplate('layout');
    expect(
        template.renderWr(),
        equals('|block 1 from layout|block 2 from '
            'layout|nested block 4 from layout|'));
  });

  test('level1', () {
    final template = env.getTemplate('level1');
    expect(
        template.renderWr(),
        equals('|block 1 from level1|block 2 from '
            'layout|nested block 4 from layout|'));
  });

  test('level2', () {
    final template = env.getTemplate('level2');
    expect(
        template.renderWr(),
        equals('|block 1 from level1|nested block 5 from '
            'level2|nested block 4 from layout|'));
  });

  test('level3', () {
    final template = env.getTemplate('level3');
    expect(
        template.renderWr(),
        equals('|block 1 from level1|block 5 from level3|'
            'block 4 from level3|'));
  });

  test('level4', () {
    final template = env.getTemplate('level4');
    expect(
        template.renderWr(),
        equals('|block 1 from level1|block 5 from '
            'level3|block 3 from level4|'));
  });

  test('super', () {
    final env = Environment(
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
    final template = env.getTemplate('c');
    expect(template.render(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
  });

  test('working', () {
    final template = env.getTemplate('working');
    expect(template, isNotNull);
  });

  test('reuse blocks', () {
    final template = env.fromSource('{{ self.foo() }}|{% block foo %}42'
        '{% endblock %}|{{ self.foo() }}');
    expect(template.render(), equals('42|42|42'));
  });
}
