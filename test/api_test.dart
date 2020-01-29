import 'package:jinja/get_field.dart';
import 'package:jinja/jinja.dart';
import 'package:test/test.dart' hide escape;

void main() {
  group('extended api', () {
    // TODO(test): item and attribute
    // test('item and attribute', () {
    //   final env = Environment(getField: getField);
    //   var template = env.fromString('{{ foo.items() | list }}');
    //   expect(template.render(foo: {'items': 42}), equals("[('items', 42)]"));
    //   template = env.fromString('foo | attr("items")() | list }}');
    //   expect(template.render(foo: {'items': 42}), equals("[('items', 42)]"));
    //   template = env.fromString('{{ foo["items"] }}');
    //   expect(template.render(foo: {'items': 42}), equals('42'));
    // });

    test('finalize', () {
      final env = Environment(finalize: (obj) => obj ?? '');
      final template =
          env.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      expect(template.render(seq: [null, 1, 'foo']), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final env = Environment(finalize: (obj) => obj ?? '');
      final template = env.fromString('<{{ none }}>');
      expect(template.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final env = Environment(finalize: (obj) => obj.runtimeType);
      final template = env.fromString('<{{ value }}>');
      expect(template.render(value: 123), equals('<int>'));
    });

    test('no finalize template data', () {
      final env = Environment(finalize: (obj) => obj.runtimeType);
      final template = env.fromString('<{{ value }}>');
      expect(template.render(value: 123), equals('<int>'));
    });
  });
}
