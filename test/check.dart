// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final env = Environment();
    final tmpl = env.fromString('{% for x in seq %}{{ loop.first }}'
        '{% for y in seq %}{% endfor %}{% endfor %}');
    print(tmpl.nodes);
    print(tmpl.render({'seq': 'ab'}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
