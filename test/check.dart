import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% macro input(name, value='', type='text', size=20) -%}
  <input type="{{ type }}" name="{{ name }}" value="{{ value|e }}" size="{{ size }}">
{%- endmacro %}
<p>{{ input('username') }}</p>
<p>{{ input('password', type='password') }}</p>
''';

void main() {
  try {
    var environment = Environment(getAttribute: getAttribute);

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

    var template = Template.fromNode(environment, body: nodes);

    print('\nmodified body:');

    for (var node in template.body.nodes) {
      print(node);
    }

    print('\nrender:');
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
