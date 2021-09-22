import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      final env = Environment();
      final tmpl = env.fromString('{{ foo["items"] }}');
      final foo = {'items': 42};
      expect(tmpl.render({'foo': foo}), equals('42'));
    });

    test('finalize', () {
      final env = Environment(finalize: (dynamic obj) => obj ?? '');
      final tmpl =
          env.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      final seq = [null, 1, 'foo'];
      expect(tmpl.render({'seq': seq}), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final env = Environment(finalize: (Object? obj) => obj ?? '');
      final tmpl = env.fromString('<{{ none }}>');
      expect(tmpl.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final env = Environment(finalize: (dynamic obj) => obj.runtimeType);
      final tmpl = env.fromString('<{{ value }}>');
      expect(tmpl.render({'value': 123}), equals('<int>'));
    });

    test('context finalize', () {
      final env = Environment(
          finalize: (Context context, Object? value) =>
              (value as dynamic) * context.resolve('scale'));
      final tmpl = env.fromString('{{ value }}');
      expect(tmpl.render({'value': 5, 'scale': 3}), equals('15'));
    });

    test('env autoescape', () {
      final env = Environment(
          finalize: (Environment environment, Object? value) =>
              '${environment.variableStart} ${repr(value)} ${environment.variableEnd}');
      final tmpl = env.fromString('{{ value }}');
      expect(tmpl.render({'value': 'hello'}), equals("{{ 'hello' }}"));
    });

    test('cycler', () {
      final items = [1, 2, 3];
      final cycler = Cycler(items);
      final iterator = cycler.iterator;

      for (final item in items + items) {
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
