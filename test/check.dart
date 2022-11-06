import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = "{{ [1, 2, 3, x] | map('default', 0) }}";

void main() {
  try {
    var environment = Environment();
    var tokens = environment.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = environment.scan(tokens);
    print('\noriginal nodes:');
    nodes.forEach(print);

    var template = Template.fromNodes(environment, nodes);

    print('\nmodified body:');
    print(template.body);

    var data = {
      'values': [
        {'name': 'Jhon'},
        {'name': 'Jhane'}
      ]
    };

    print('\ngenerate:');
    print(template.generate(data));

    print('render:');
    print(template.render(data));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
