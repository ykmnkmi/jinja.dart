// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString('{{ foo|first }}');
    print(template.nodes);
    print(template.render({'foo': range(10)}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
