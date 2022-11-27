import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''{{ '<">&'|escape }}''';

void main() {
  try {
    var environment = Environment(getAttribute: getAttribute);
    environment.filters;
    var tokens = environment.lex(source);
    print('tokens:');

    for (var token in tokens) {
      print('${token.type}: ${token.value}');
    }

    var nodes = environment.scan(tokens);
    print('\noriginal nodes:');

    for (var node in nodes) {
      print(node);
    }

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
