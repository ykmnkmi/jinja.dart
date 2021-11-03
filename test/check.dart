// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '{% for item in seq %}{{ x }}'
    '{% set x = item %}{{ x }}{% endfor %}';

void main() {
  try {
    var env = Environment(fieldGetter: fieldGetter, optimized: false);
    var tokens = env.lex(source);
    // print(tokens);
    var nodes = env.parse(tokens);
    print(nodes);
    var template = Template.parsed(env, nodes);
    print(template.nodes);
    print(template.render({'x': 0, 'seq': [1, 2, 3]}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
