import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/src/context.dart';
import 'package:test/test.dart';

Object? testFuncWithContext(Context context, {String namedArg1 = 'default'}) {
  var bar = context.get('bar');
  return namedArg1+bar.toString();
}

Object? testFuncWithoutContext({String namedArg1 = 'default'}) {
  return namedArg1;
}

void main() {
  group('No Context', () {
    test('Named Argument', () {
      var env = Environment(globals: {'test_func': testFuncWithoutContext});
      var out = env.fromString("{{ test_func(namedArg1='testing') }}");
      expect(out.render(), 'testing');
    });
  });
  group('With Context', () {
    test('Named Argument', () {
      var data = {'bar': 42};
      var env = Environment(
        getAttribute: getAttribute,
        globals: {'test_func': passContext(testFuncWithContext)},
      );
      var out = env.fromString("{{ test_func(namedArg1='testing') }}");
      expect(out.render(data), 'testing42');
    });
    test('Named Argument Missing', () {
      var data = {'bar': 42};
      var env = Environment(
        getAttribute: getAttribute,
        globals: {'test_func': passContext(testFuncWithContext)},
      );
      var out = env.fromString("{{ test_func() }}");
      expect(out.render(data), 'default42');
    });
  });
}