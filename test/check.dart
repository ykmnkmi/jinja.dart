// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''{{ "o" is eq "o" }}''';

void main() {
  try {
    var env = Environment(fieldGetter: fieldGetter);
    // var tokens = env.lex(source);
    // print(tokens);
    var nodes = env.parse(source);
    print(nodes);
    var template = Template.parsed(env, nodes);
    print(template.nodes);
    print(template.render({'x': 0, 'seq': [1, 2, 3]}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
