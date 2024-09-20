// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:jinja/jinja.dart';

const Map<String, String> sources = <String, String>{
  'include': '{% macro test(foo) %}[{{ foo }}]{% endmacro %}',
};

void main() {
  var loader = MapLoader(sources);
  var env = Environment(loader: loader);
  var tmpl = env.fromString('''
{% from "include" import test -%}
{{ test("foo") }}''');
  print(JsonEncoder.withIndent('  ').convert(env.getTemplate('include').body.toJson()));
  print(tmpl.render());
}
