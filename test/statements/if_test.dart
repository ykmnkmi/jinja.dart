import 'package:jinja/jinja.dart';
import 'package:test/test.dart';

void main() {
  final env = Environment();

  test('simple', () {
    final template = env.fromSource('''{% if true %}...{% endif %}''');
    expect(template.testRender(), equals('...'));
  });

  test('elif', () {
    final template = env.fromSource('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
    expect(template.testRender(), equals('...'));
  });

  test('elif deep', () {
    final source = '{% if a == 0 %}0' +
        List.generate(999, (i) => '{% elif a == ${i + 1} %}${i + 1}').join() +
        '{% else %}x{% endif %}';
    final template = env.fromSource(source);
    expect(template.testRender(a: 0), equals('0'));
    expect(template.testRender(a: 10), equals('10'));
    expect(template.testRender(a: 999), equals('999'));
    expect(template.testRender(a: 1000), equals('x'));
  });

  test('else', () {
    final template =
        env.fromSource('{% if false %}XXX{% else %}...{% endif %}');
    expect(template.testRender(), equals('...'));
  });

  test('empty', () {
    final template = env.fromSource('[{% if true %}{% else %}{% endif %}]');
    expect(template.testRender(), equals('[]'));
  });

  test('complete', () {
    final template = env.fromSource('{% if a %}A{% elif b %}B{% elif c == d %}'
        'C{% else %}D{% endif %}');
    expect(template.testRender(a: 0, b: false, c: 42, d: 42.0), equals('C'));
  });

  test('no scope', () {
    var template =
        env.fromSource('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
    expect(template.testRender(a: true), equals('1'));
    template =
        env.fromSource('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
    expect(template.testRender(), equals('1'));
  });
}
