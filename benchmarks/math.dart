// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    Template template = Template('{{ (x + y) * z / w }}');
    MathOperations(template).report();
  } catch (error, stackTrace) {
    print(error);
    print(Trace.format(stackTrace));
  }
}

@pragma('vm:never-inline')
void doWork(String render) {}

final class MathOperations extends BenchmarkBase {
  const MathOperations(this.template) : super('Math Operations');

  final Template template;

  @override
  void run() {
    for (int i = 0; i < 100000; i += 1) {
      doWork(template.render({'x': 1, 'y': 2, 'z': 3, 'w': 4}));
    }
  }
}
