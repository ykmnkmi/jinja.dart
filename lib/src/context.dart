import 'environment.dart';
import 'markup.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, {this.parent, Map<String, Object?>? data})
      : context = <String, Object?>{...environment.globals, ...?data} {
    context
      ..['context'] = this
      ..['ctx'] = this
      ..['environment'] = environment
      ..['env'] = environment
      ..['autoescape'] = environment.autoEscape;
  }

  final Environment environment;

  final Map<String, Object?>? parent;

  final Map<String, Object?> context;

  // TODO: remove
  bool get autoEscape {
    return resolve('autoescape') as bool;
  }

  Object? call(dynamic object,
      [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    var function = object.call as Function;
    positional ??= <Object?>[];
    return Function.apply(function, positional, named);
  }

  Context derived() {
    return Context(environment, parent: context);
  }

  Object? escape(Object? value, [bool escaped = false]) {
    if (value == null) {
      return null;
    }

    if (value is Markup) {
      return value;
    }

    if (autoEscape) {
      if (escaped) {
        return Markup.escaped(value);
      }

      return Markup.escape(value);
    }

    return value;
  }

  bool has(String key) {
    if (context.containsKey(key)) {
      return true;
    }

    var parent = this.parent;

    if (parent == null) {
      return false;
    }

    return parent.containsKey(key);
  }

  Object? get(String key) {
    return context[key];
  }

  Object? resolve(String key) {
    if (context.containsKey(key)) {
      return context[key];
    }

    var parent = this.parent;

    if (parent == null) {
      return null;
    }

    return parent[key];
  }

  Object? filter(
      String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callFilter(name, positional, named, this);
  }

  bool test(String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callTest(name, positional, named);
  }
}
