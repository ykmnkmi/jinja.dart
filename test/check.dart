// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var env = Environment();
    var tokens = env.lex('{% for i in range(5) %}{{ loop.index }}{% endfor %}');
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
