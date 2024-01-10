import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';
import 'package:test/test.dart' as t;

final Environment env = Environment(getAttribute: getAttribute);

final Environment envTrim = Environment(
  getAttribute: getAttribute,
  trimBlocks: true,
);

extension EnvironmentTest on Environment {
  void from(
    String source, {
    String? path,
    Map<String, Object?>? globals,
  }) {
    var template = fromString(source, path: path, globals: globals);
    t.expect(template, t.isA<Template>());
  }

  void fromThrows<T>(
    String source, {
    String? path,
    Map<String, Object?>? globals,
    bool Function(T)? predicate,
  }) {
    Template callback() {
      return fromString(source, path: path, globals: globals);
    }

    if (predicate == null) {
      t.expect(callback, t.throwsA(t.isA<T>()));
    } else {
      t.expect(callback, t.throwsA(t.predicate<T>(predicate)));
    }
  }

  void render(
    String source, {
    String? path,
    Map<String, Object?>? globals,
    Map<String, Object?>? data,
    required String equals,
  }) {
    var template = fromString(source, path: path, globals: globals);
    t.expect(template.render(data), t.equals(equals));
  }

  void renderThrows<T>(
    String source, {
    Map<String, Object?>? data,
    bool Function(T)? predicate,
  }) {
    String callback() {
      return fromString(source).render(data);
    }

    if (predicate == null) {
      t.expect(callback, t.throwsA(t.isA<T>()));
    } else {
      t.expect(callback, t.throwsA(t.predicate<T>(predicate)));
    }
  }
}
