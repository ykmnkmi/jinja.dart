import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/src/context.dart';
import 'package:test/test.dart';

Object? testFuncWithContext(Context context, {String namedArgument = 'default'}) {
  var bar = context.get('bar');
  return namedArgument+bar.toString();
}

Object? testFuncWithoutContext({String namedArgument = 'default'}) {
  return namedArgument;
}

Object? testFuncWithEnvironment(Environment env, String positionalArgument, {String namedArgument = 'default'}) {
  return "[$positionalArgument] {$namedArgument} env.commentStart = ${env.commentStart}";
}

void main() {
  group('No Context', () {
    test('named argument', () {
      var env = Environment(globals: {'test_func': testFuncWithoutContext});
      var out = env.fromString("{{ test_func(namedArgument='testing') }}");
      expect(out.render(), 'testing');
    });
  });
  group('With Context', () {
    test('named argument', () {
      var data = {'bar': 42};
      var env = Environment(
        getAttribute: getAttribute,
        globals: {'test_func': passContext(testFuncWithContext)},
      );
      var out = env.fromString("{{ test_func(namedArgument='testing') }}");
      expect(out.render(data), 'testing42');
    });
    test('named argument missing', () {
      var data = {'bar': 42};
      var env = Environment(
        getAttribute: getAttribute,
        globals: {'test_func': passContext(testFuncWithContext)},
      );
      var out = env.fromString("{{ test_func() }}");
      expect(out.render(data), 'default42');
    });
  });
  group('With Environment', ()
  {
    test('positional argument', () {
      var data = {'bar': 42};
      var env = Environment(
        getAttribute: getAttribute,
        globals: {'test_func': passEnvironment(testFuncWithEnvironment)},
      );
      var out = env.fromString("{{ test_func('positional argument value') }}");
      expect(out.render(data), '[positional argument value] {default} env.commentStart = {#');
    });
  });
}