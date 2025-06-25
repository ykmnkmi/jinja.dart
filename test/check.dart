// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/optimizer.dart';
import 'package:jinja/src/runtime.dart';

const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');

const String source = '''
{{ x + y }}''';

void main() {
  var environment = Environment();

  var tokens = environment.lex(source);
  // print('tokens:');

  // for (var token in tokens) {
  //   print('${token.type}: ${token.value}');
  // }

  var body = environment.scan(tokens);
  var original = jsonEncoder.convert(body.toJson());

  body = body.accept(const Optimizer(), Context(environment));

  var optimized = jsonEncoder.convert(body.toJson());

  body = body.accept(RuntimeCompiler(), null);

  var compiled = jsonEncoder.convert(body.toJson());
  compare(original, optimized, compiled);

  var template = Template.fromNode(environment, body: body);

  try {
    print('render:');
    print(template.render({'x': 1, 'y': 2}));
  } on UndefinedError catch (error) {
    print(error.message);
  }
}

const LineSplitter splitter = LineSplitter();

void compare(
  String originalJson,
  String optimizedJson,
  String compiledJson,
) {
  if (!stdout.hasTerminal) {
    return;
  }

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
