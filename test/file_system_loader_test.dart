@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';
import 'package:test/test.dart';

void main() {
  var pathUri = Directory.current.uri.resolve('test/res/templates');
  var paths = <String>[pathUri.path];

  group('FileSystemLoader', () {
    test('paths', () {
      var loader = FileSystemLoader(paths: paths);
      var env = Environment(loader: loader);
      var tmpl = env.getTemplate('test.html');
      expect(tmpl.render().trim(), equals('BAR'));
      tmpl = env.getTemplate('foo/test.html');
      expect(tmpl.render().trim(), equals('FOO'));
    });

    test('utf8', () {
      var loader = FileSystemLoader(
          paths: paths, extensions: <String>{'txt'}, encoding: utf8);
      var env = Environment(loader: loader);
      var tmpl = env.getTemplate('mojibake.txt');
      expect(tmpl.render().trim(), equals('文字化け'));
    });

    test('iso-8859-1', () {
      var loader = FileSystemLoader(
          paths: paths, extensions: <String>{'txt'}, encoding: latin1);
      var env = Environment(loader: loader);
      var tmpl = env.getTemplate('mojibake.txt');
      expect(tmpl.render().trim(), equals('æ\x96\x87\xe5\xad\x97\xe5\x8c\x96\xe3\x81\x91'));
    });
  });
}
