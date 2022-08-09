import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% set ns = namespace(self=37) %}
{{ ns.self }}
{% set ns.self = 38 %}
{{ ns.self }}''';

void main() {
  try {
    var environment = Environment();
    var tokens = environment.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = environment.scan(tokens);
    print('\noriginal nodes:');
    nodes.forEach(print);

    for (var node in nodes) {
      for (var modifier in environment.modifiers) {
        modifier(node);
      }
    }

    print('\nmodified nodes:');
    nodes.forEach(print);

    var template = Template.fromNodes(environment, nodes);

    print('\ngenerate:');
    print(template.generate());

    print('render:');
    print(template.render());
  } on TemplateError catch (error, trace) {
    print(error.message);
    print(Trace.format(trace, terse: true));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
