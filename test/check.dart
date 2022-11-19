import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '{{ words|map(attribute="length") }}';

void main() {
  try {
    var environment = Environment(getAttribute: getAttribute);
    var tokens = environment.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = environment.scan(tokens);
    print('\noriginal nodes:');
    nodes.forEach(print);

    var template = Template.fromNodes(environment, nodes);

    print('\nmodified body:');
    print(template.body);

    var words = ['foo', 'bar'];
    var data = {'words': words};

    // print('\ngenerate:');
    // print(template.generate(data).join());

    print('\nrender:');
    print(template.render(data));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
