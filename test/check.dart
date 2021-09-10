// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:jinja/src/filters.dart';

void main() {
  try {
    final environment = Environment(optimized: false);
    final template = environment.fromString('{{ " ..abc.."|trim(".") }}');
    print(template.nodes);
    print(template.render());
    print(doTrim(' ..abc..', '.'));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
