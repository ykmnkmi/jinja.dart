import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:jinja/src/visitor.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% macro say_hello(name) %}Hello {{ name }}!{% endmacro %}
{{ say_hello('Peter') }}''';

const Map<String, Object?> context = <String, Object?>{};

void main() {
  try {
    var environment = Environment();

    var tokens = environment.lex(source);
    // print('tokens:');

    // for (var token in tokens) {
    //   print('${token.type}: ${token.value}');
    // }

    var printer = Printer(environment);

    var body = environment.scan(tokens);
    print('\noriginal nodes:');
    print(printer.visit(body));

    body = body.accept(const Optimizer(), Context(environment));
    print('\noptimized body:');
    print(printer.visit(body));

    var macroses = <String>{};
    body = body.accept(const RuntimeCompiler(), macroses);
    print('\nmacroses: ${macroses.join(', ')}');
    print('\ncompiled body:');
    print(printer.visit(body));

    var template = Template.fromNode(environment, body: body);
    print('\nrender:');
    print(template.render(context));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
