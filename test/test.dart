import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

const String layout = '''
|{% block block1 %}1{% endblock %}
|{% block block2 %}2{% endblock %}
|{% block block3 %}{% block block4 %}nested 4{% endblock %}{% endblock %}''';

const String level1 = '''
{% extends "layout" %}
{% block block1 %}1 level-1{% endblock %}''';

const String level2 = '''
{% extends "level1" %}
{% block block2 %}{% block block5 %}nested 5 level-2{%
endblock %}{% endblock %}''';

const Map<String, String> sources = <String, String>{
  'layout': layout,
  'level1': level1,
  'level2': level2,
};

void main() {
  try {
    var loader = MapLoader(sources);
    var environment = Environment(loader: loader, trimBlocks: true);
    var template = environment.getTemplate('level2');
    template.blocks.forEach(print);

    var data = <String, Object?>{};
    print(template.render(data));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
