import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = "{{ [1, 2, 3, x] | map('default', 0) }}";

void main() {
  try {
    var environment = Environment();
    var template = environment.fromString(source);
    var data = <String, Object?>{'x': null};
    print(template.render(data));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
