import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''{% set ns = namespace(d, self=37) %}{% set ns.b = 42 %}{{ ns.a }}|{{ ns.self }}|{{ ns.b }}''';

void main() {
  try {
    var env = Environment(autoEscape: true, fieldGetter: fieldGetter);
    var tokens = env.lex(source);
    print('tokens:');
    tokens.forEach(print);

    var nodes = env.parser.scan(tokens);
    // var nodes = env.parse(source);
    print('\noriginal nodes:');
    nodes.forEach(print);

    var template = Template.parsed(env, nodes);

    for (var modifier in env.modifiers) {
      modifier(template);
    }

    print('\nmodified nodes:');
    template.nodes.forEach(print);

    print('\ngenerate:');
    print(template.generate({'d': {'a': 13}}));

    print('render:');
    print(template.render({'d': {'a': 13}}));
  } on TemplateError catch (error, trace) {
    print(error.message);
    print(Trace.format(trace, terse: true));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages