import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/nodes.dart' as AST;
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% set ns = namespace(self=37) %}
{{ ns.self }}
{% set ns.self = 38 %}
{{ ns.self }}''';

void main() {
  try {
    var env = Environment();
    var tokens = env.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = env.scan(tokens);
    // var nodes = env.parse(source);
    print('\noriginal nodes:');
    nodes.forEach(print);

    var body = AST.Template(nodes);

    for (var modifier in env.modifiers) {
      modifier(body);
    }

    print('\nmodified nodes:');
    body.nodes.forEach(print);

    Compiler.compile(body, env);

    var template = Template.parsed(env, body);

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
