// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var env = Environment();
    var tmpl = env.fromString('''{% for item in [1, 2, 3, 5] -%}{{ loop.previtem | upper }}{%- endfor %}''');
    print(tmpl.nodes);
    print(tmpl.blocks);
    print(tmpl.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
