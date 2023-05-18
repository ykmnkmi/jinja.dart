import 'package:jinja/reflection.dart';
import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% for item in seq %}{{ loop.cycle('<1>', '<2>') }}{% endfor %}
{% for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''';

void main() {
  try {
    var environment = Environment(getAttribute: getAttribute);

    var tokens = environment.lex(source);
    print('tokens:');

    for (var token in tokens) {
      print('${token.type}: ${token.value}');
    }

    var printer = Printer(environment);

    var body = environment.scan(tokens);
    print('\noriginal nodes:');
    print(printer.visit(body));

    body = body.accept(const Optimizer(), Context(environment));
    print('\noptimized body:');
    print(printer.visit(body));

    body = body.accept(const RuntimeCompiler(), null);
    print('\ncompiled body:');
    print(printer.visit(body));

    var template = Template.fromNode(environment, body: body);

    print('\nrender:');
    print(template.render({'seq': range(4), 'through': ['<1>', '<2>']}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
