// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''{{ "Hello " ~ name ~ "!" }}''';

void main() {
  try {
    var env = Environment();
    var tokens = env.lex(source);
    print(tokens);
    env.parser.scan(tokens);
    var nodes = env.parse(source);
    print(nodes);
    var template = Template.parsed(env, nodes);
    print(template.nodes);
    print(template.generate());
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
