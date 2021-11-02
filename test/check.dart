// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% with a=42, b=23 -%}
  {{ a }} = {{ b }}
{% endwith -%}
  {{ a }} = {{ b }}''';

void main() {
  try {
    var env = Environment(fieldGetter: fieldGetter, optimized: false);
    var tokens = env.lex(source);
    // print(tokens);
    var nodes = env.parse(tokens);
    print(nodes);
    var template = Template.parsed(env, nodes);
    print(template.nodes);
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
