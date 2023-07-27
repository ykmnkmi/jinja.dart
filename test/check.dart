// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:stack_trace/stack_trace.dart';

const String source = '''\
{% macro test(name='world') %}{{ kwargs }}{% endmacro %}
{{ test(a=1, name='jhon') }}''';

const Map<String, Object?> context = <String, Object?>{};

const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');

void main() {
  try {
    var environment = Environment(leftStripBlocks: true, trimBlocks: true);

    var tokens = environment.lex(source);
    // print('tokens:');

    // for (var token in tokens) {
    //   print('${token.type}: ${token.value}');
    // }

    var body = environment.scan(tokens);
    // var original = jsonEncoder.convert(body.toJson());

    body = body.accept(const Optimizer(), Context(environment));

    // var optimized = jsonEncoder.convert(body.toJson());

    body = body.accept(RuntimeCompiler(), <String>{});

    // var compiled = jsonEncoder.convert(body.toJson());
    // compare(original, optimized, compiled);

    var template = Template.fromNode(environment, body: body);
    print('render:');
    print(template.render(context));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}

const LineSplitter splitter = LineSplitter();

void compare(
  String originalJson,
  String optimizedJson,
  String compiledJson,
) {
  var original = <String?>['original:', ...splitter.convert(originalJson)];
  var optimized = <String?>['optimized:', ...splitter.convert(optimizedJson)];
  var compiled = <String?>['compiled:', ...splitter.convert(compiledJson)];

  var length = max(original.length, max(optimized.length, compiled.length));

  original.length = length;
  optimized.length = length;
  compiled.length = length;

  var width = (stdout.terminalColumns - 8) ~/ 3;
  var spaces = ' ' * width;

  void write(String? line) {
    if (line == null) {
      stdout.write(spaces);
    } else {
      if (line.length > width) {
        stdout.write(line.substring(0, width - 3));
        stdout.write('...');
      } else if (line.length < width) {
        stdout.write(line.padRight(width));
      } else {
        stdout.write(line);
      }
    }
  }

  for (var index = 0; index < length; index += 1) {
    stdout.write(' ');
    write(original[index]);
    stdout.write(' | ');
    write(optimized[index]);
    stdout.write(' | ');
    write(compiled[index]);
    stdout.writeln(' ');
  }
}
