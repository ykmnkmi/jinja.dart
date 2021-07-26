import 'package:jinja/jinja.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart' hide escape;

void main() {
  group('FileSystemLoader', () {
    final searchPath = join('test', 'res', 'templates');

    void testCommon(Environment env) {
      final tmpl = env.getTemplate('test.html');
      expect(tmpl.renderMap().trim(), equals('BAR'));
    }

    test('searchPath as string', () {
      final fileSystemLoader = FileSystemLoader(path: searchPath);
      final env = Environment(loader: fileSystemLoader);
      print(fileSystemLoader.paths);
      testCommon(env);
    });
  });
}
