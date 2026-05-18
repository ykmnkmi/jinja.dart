@TestOn('vm')
library;

import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:jinja/src/runtime.dart';
import 'package:test/test.dart';

Object? func({String named = 'default'}) {
  return named;
}

Object? funcWithEnvironment(
  Environment env,
  String positional, {
  String named = 'default',
}) {
  return '[$positional] {$named} env.commentStart = ${env.commentStart}';
}

Object? funcWithContext(Context context, {String named = 'default'}) {
  var bar = context.resolve('bar');
  return named + bar.toString();
}

void main() {
  group('Call', () {
    test('named argument', () {
      var env = Environment(globals: {'test_func': func});
      var tmpl = env.fromString('{{ test_func(named="testing") }}');
      expect(tmpl.render(), 'testing');
    });
  });

  group('Call with Environment', () {
    test('positional argument', () {
      var globals = {'test_func': passEnvironment(funcWithEnvironment)};
      var env = Environment(getAttribute: getAttribute, globals: globals);
      var tmpl = env.fromString('{{ test_func("positional") }}');
      var data = {'bar': 42};
      expect(tmpl.render(data), '[positional] {default} env.commentStart = {#');
    });
    test('named argument', () {
      var globals = {'test_func': passEnvironment(funcWithEnvironment)};
      var env = Environment(getAttribute: getAttribute, globals: globals);
      var tmpl = env.fromString('{{ test_func("positional", named="named") }}');
      var data = {'bar': 42};
      expect(tmpl.render(data), '[positional] {named} env.commentStart = {#');
    });
  });

  group('Call with Context', () {
    test('named argument', () {
      var globals = {'test_func': passContext(funcWithContext)};
      var env = Environment(getAttribute: getAttribute, globals: globals);
      var tmpl = env.fromString("{{ test_func(named='testing') }}");
      var data = {'bar': 42};
      expect(tmpl.render(data), 'testing42');
    });

    test('named argument missing', () {
      var globals = {'test_func': passContext(funcWithContext)};
      var env = Environment(getAttribute: getAttribute, globals: globals);
      var tmpl = env.fromString('{{ test_func() }}');
      var data = {'bar': 42};
      expect(tmpl.render(data), 'default42');
    });
  });
}
