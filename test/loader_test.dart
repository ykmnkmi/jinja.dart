import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart' hide escape;

void main() {
  group('FileSystemLoader', () {
    late String searchPath;

    setUpAll(() {
      if (Platform.script.isScheme('file')) {
        searchPath = p.join(
            Platform.script
                .resolve('.')
                .toFilePath(windows: Platform.isWindows),
            'res',
            'templates');
      } else {
        searchPath = p.join('test', 'res', 'templates');
      }
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
