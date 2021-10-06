import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      var env = Environment();
      var tmpl = env.fromString('{{ foo["items"] }}');
      var foo = {'items': 42};
      expect(tmpl.render({'foo': foo}), equals('42'));
    });

    test('finalize', () {
      var env = Environment(finalize: (dynamic obj) => obj ?? '');
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
      var env = Environment(finalize: (dynamic obj) => obj.runtimeType);
      var tmpl = env.fromString('<{{ value }}>');
      expect(tmpl.render({'value': 123}), equals('<int>'));
    });

    test('context finalize', () {
      var env = Environment(
          finalize: (Context context, Object? value) =>
              (value as dynamic) * context.resolve('scale'));
      var tmpl = env.fromString('{{ value }}');
      expect(tmpl.render({'value': 5, 'scale': 3}), equals('15'));
    });

    test('env autoescape', () {
      var env = Environment(
          finalize: (Environment environment, Object? value) =>
              '${environment.variableStart} ${repr(value)} ${environment.variableEnd}');
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
