// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

const Map<String, String> sources = <String, String>{
  'base.jinja': '''
<html>
<body>
  {% block content %}{% endblock %}
</body>
</html>''',
  'component.jinja': '''
{% macro component(data) %}
  {{ data }}
{% endmacro %}''',
  'page.jinja': '''
{% extends "base.jinja" %}

{% import 'component.jinja' as components %}

{% block content %}
  {{ components.component("hey") }}
{% endblock %}''',
};
void main() {
  Loader loader = MapLoader(sources);

  Environment environment = Environment(loader: loader);

  try {
    Template page = environment.getTemplate('page.jinja');
    print(const JsonEncoder.withIndent('  ').convert(page.body.toJson()));
    print(page.render());
  } catch (error, stackTrace) {
    print(error);
    print(Trace.format(stackTrace));
  }
}
