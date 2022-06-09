import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''{{ name['key'] }}''';

void main() {
  try {
    var env = Environment(autoEscape: true, fieldGetter: fieldGetter);
    var tokens = env.lex(source);
    print(tokens);

    var nodes = env.parser.scan(tokens);
    // var nodes = env.parse(source);
    print(nodes);

    var template = Template.parsed(env, nodes);
    print(template.nodes);
    print(template.generate({'name': 'world'}));
    print(template.render({'name': 'world'}));
  } on TemplateError catch (error, trace) {
    print(error.message);
    print(Trace.format(trace, terse: true));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages