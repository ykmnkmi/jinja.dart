@TestOn('vm || chrome')
library;

import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

MapLoader mapLoader() {
  return MapLoader({'justdict.html': 'FOO'});
}

void main() {
  group('Loaders', () {
    test('MapLoader', () {
      var env = Environment(loader: mapLoader());
      var tmpl = env.getTemplate('justdict.html');
      expect(tmpl.render().trim(), equals('FOO'));
      expect(() => env.getTemplate('missing.html'),
          throwsA(isA<TemplateNotFound>()));
    });
  });
}
