import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      final environment = Environment(getField: getField);

      expect(
          environment.fromString('{{ foo["items"] }}').render({
            'foo': {'items': 42}
          }),
          equals('42'));
    });

    test('finalize', () {
      final environment = Environment(finalize: (dynamic obj) => obj ?? '');

      expect(
          environment
              .fromString('{% for item in seq %}|{{ item }}{% endfor %}')
              .render({
            'seq': [null, 1, 'foo']
          }),
          equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final environment = Environment(
        finalize: (dynamic obj) => obj ?? '',
      );

      expect(environment.fromString('<{{ none }}>').render(), equals('<>'));
    });

    test('no finalize template data', () {
      final environment =
          Environment(finalize: (dynamic obj) => obj.runtimeType);
      // if template data was finalized, it would print 'StringintString'.
      expect(environment.fromString('<{{ value }}>').render({'value': 123}),
          equals('<int>'));
    });

    test('context finalize', () {
      final environment = Environment(
        finalize: (Context context, dynamic value) {
          return value * context['scale'];
        },
      );

      expect(
          environment
              .fromString('{{ value }}')
              .render({'value': 5, 'scale': 3}),
          equals('15'));
    });

    test('env autoescape', () {
      final environment = Environment(
        finalize: (Environment environment, dynamic value) {
          return '${environment.variableBegin} ${represent(value)} ${environment.variableEnd}';
        },
      );

      expect(environment.fromString('{{ value }}').render({'value': 'hello'}),
          equals("{{ 'hello' }}"));
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
