import 'package:jinja/jinja.dart';
import 'package:jinja/src/visitor.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var environment = Environment(
      loader: MapLoader({
        'default': '{% block x required %}data {# #}{% endblock %}',
        'default2':
            '{% block x required %}{% block y %}{% endblock %}  {% endblock %}',
        'default3':
            '{% block x required %}{% if true %}{% endif %}  {% endblock %}',
        'level1default1':
            '{% extends "default" %}{%- block x %}CHILD{% endblock %}',
        'level1default2':
            '{% extends "default2" %}{%- block x %}CHILD{% endblock %}',
        'level1default3':
            '{% extends "default3" %}{%- block x %}CHILD{% endblock %}'
      }),
    );

    var template = environment.getTemplate('level1default3');
    Printer(environment).visit(template.body);
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
