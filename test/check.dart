// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var env = Environment();
    var tmpl = env.fromString('{% set ns = namespace(a=1) %}{% set ns.b = 2 %}{{ ns.a }}');
    print(tmpl.nodes);
    print(tmpl.blocks);
    print(tmpl.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
