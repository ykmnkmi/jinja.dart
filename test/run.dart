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
</html>
''',
  'page.jinja': '''
{% extends "base.jinja" %}

{% from "components.jinja" import component %}

{% block content %}
  {{ component("Hey!") }}
{% endblock %}
''',
  'components.jinja': '''
{% macro component(data) %}
  {{ data }}
{% endmacro %}
''',
};

void main() {
  Environment environment = Environment(loader: MapLoader(sources));

  try {
    Template page = environment.getTemplate('page.jinja');
    print(const JsonEncoder.withIndent('  ').convert(page.body.toJson()));
    print(page.render());
  } catch (error, stackTrace) {
    print(error);
    print(Trace.format(stackTrace));
  }
}
