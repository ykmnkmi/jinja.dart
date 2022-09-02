import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '{{ values | map(item="name") | join(", ") }}';

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

    print('\nmodified nodes:');
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
  } on TemplateError catch (error, trace) {
    print(error.message);
    print(Trace.format(trace, terse: true));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
