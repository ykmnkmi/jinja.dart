// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var env = Environment();
    var tmpl = env.fromString('{% for item in seq %}{{ loop.changed(item) }},{% endfor %}');
    print(tmpl.nodes);
    print(tmpl.blocks);
    print(tmpl.render({'seq': [null, null, 1, 2, 2, 3, 4, 4, 4]}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
