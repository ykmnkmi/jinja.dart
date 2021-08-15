// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString(
        '{% filter upper|replace(\'FOO\', \'foo\') %}foobar{% endfilter %}');
    print(template.nodes);
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
