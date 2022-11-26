import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '{% set foo.bar = 1 %}';

void main() {
  try {
    var environment = Environment(getAttribute: getAttribute);
    environment.filters;
    var tokens = environment.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = environment.scan(tokens);
    print('\noriginal nodes:');
    nodes.forEach(print);

    var template = Template.fromNodes(environment, nodes);

    print('\nmodified body:');
    print(template.body);

    var emptyMap = <String, Object?>{};
    var data = {'foo': emptyMap};

    print('\nrender:');
    print(template.render(data));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
