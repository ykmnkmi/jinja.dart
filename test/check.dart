// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:jinja/loaders.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/src/compiler.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/optimizer.dart';

class User {
  const User(this.name);

  final String? name;
}

const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');

const String source = '''
{{ users|map(attribute="name")|join("|") }}''';

const Map<String, Object?> globals = <String, Object?>{'bar': 23};

const Map<String, Object?> context = <String, Object?>{
  'foo': 42,
  'seq': <int>[1, 2],
  'through': <String>['<1>', '<2>'],
  'users': <User>[User('john'), User('jane'), User('mike')]
};

const Map<String, String> sources = <String, String>{
  'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
};

void main() {
  var environment = Environment(
    leftStripBlocks: true,
    trimBlocks: true,
    loader: MapLoader(sources),
    globals: globals,
    getAttribute: getAttribute,
  );

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
  print('render:');
  print(template.render(context));
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
