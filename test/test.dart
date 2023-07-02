import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var environment = Environment(leftStripBlocks: true);
    var template = environment.fromString(' {{+ name }}!');
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
