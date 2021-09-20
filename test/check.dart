// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final env = Environment();
    final tmpl = env.fromString('{{  x is escaped }}');
    print(tmpl.nodes);
    print(tmpl.render({'x': 'foo'}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
