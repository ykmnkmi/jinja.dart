// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final env = Environment(globals: {
      'foo': (dynamic a, dynamic b, {dynamic c, dynamic e, dynamic g}) {
        return a + b + c + e + g;
      }
    });

    final tmpl = env.fromString('{{ foo("a", c="d", e="f", *["b"], **{"g": "h"}) }}');
    print(tmpl.nodes);
    print(tmpl.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
