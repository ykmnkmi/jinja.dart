import 'dart:io';

import 'package:jinja/src/environment.dart';
import 'package:jinja/src/loaders.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart' hide escape;

void main() {
  group('FileSystemLoader', () {
    String searchPath;

    setUpAll(() {
      searchPath =
          p.join(Platform.script.resolve('.').toFilePath(), 'res', 'templates');
    });

    void testCommon(Environment env) {
      final tmpl = env.getTemplate('test.html');
      expect(tmpl.render().trim(), equals('BAR'));
    }

    test('searchPath as string', () {
      final fileSystemLoader = FileSystemLoader(path: searchPath);
      final env = Environment(loader: fileSystemLoader);
      testCommon(env);
    });
  });
}
