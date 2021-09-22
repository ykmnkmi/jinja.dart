// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final env = Environment();
    final tmpl = env.fromString('{% set ns = namespace() %}{% set ns.bar = "42" %}{{ ns.bar }}');
    print(tmpl.nodes);
    print(tmpl.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
