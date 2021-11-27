import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

import 'package:jinja/src/context.dart';
import 'package:jinja/src/utils.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      var env = Environment();
      var tmpl = env.fromString('{{ foo["items"] }}');
      var foo = {'items': 42};
      expect(tmpl.render({'foo': foo}), equals('42'));
    });

    test('finalize', () {
      var env = Environment(finalize: (Object? obj) => obj ?? '');
      var tmpl = env.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      var seq = [null, 1, 'foo'];
      expect(tmpl.render({'seq': seq}), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      var env = Environment(finalize: (Object? obj) => obj ?? '');
      var tmpl = env.fromString('<{{ none }}>');
      expect(tmpl.render(), equals('<>'));
    });

    test('no finalize template data', () {
      var env = Environment(finalize: (Object? obj) => obj.runtimeType);
      var tmpl = env.fromString('<{{ value }}>');
      expect(tmpl.render({'value': 123}), equals('<int>'));
    });

    test('context finalize', () {
      Object? finalize(Context context, dynamic value) =>
          value * context.resolve('scale');
      var env = Environment(finalize: finalize);
      var tmpl = env.fromString('{{ value }}');
      expect(tmpl.render({'value': 5, 'scale': 3}), equals('15'));
    });

    test('env autoescape', () {
      Object? finalize(Environment environment, Object? value) =>
          '${environment.variableStart} ${repr(value)} ${environment.variableEnd}';
      var env = Environment(finalize: finalize);
      var tmpl = env.fromString('{{ value }}');
      expect(tmpl.render({'value': 'hello'}), equals("{{ 'hello' }}"));
    });

    test('cycler', () {
      var items = [1, 2, 3];
      var cycler = Cycler(items);
      var iterator = cycler.iterator;

      for (var item in items + items) {
        expect(cycler.current, equals(item));
        iterator.moveNext();
        expect(iterator.current, equals(item));
      }

      iterator.moveNext();
      expect(cycler.current, equals(2));
      cycler.reset();
      expect(cycler.current, equals(1));
    });

    // TODO: add test: autoescape autoselect
  });
}
