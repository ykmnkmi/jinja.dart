import 'package:jinja/reflection.dart';
import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''
{% set ns = namespace(d, self=37) %}''';

void main() {
  try {
    var environment = Environment(
      getAttribute: getAttribute,
      leftStripBlocks: true,
      trimBlocks: false,
    );

    var tokens = environment.lex(source);
    print('tokens:');

    for (var token in tokens) {
      print('${token.type}: ${token.value}');
    }

    var body = environment.scan(tokens);
    print('\noriginal nodes:');
    print(body);

    body = body.accept(const Optimizer(), Context(environment));
    print('\noptimized body:');
    print(body);

    body = body.accept(const RuntimeCompiler(), null);
    print('\ncompiled body:');
    print(body);

    var template = Template.fromNode(environment, body: body);

    print('\nrender:');
    print(template.render({'d': {}}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}

// ignore_for_file: avoid_print, depend_on_referenced_packages
