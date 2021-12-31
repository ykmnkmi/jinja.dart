import 'environment.dart';
import 'markup.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, {this.parent, Map<String, Object?>? data})
      : context = <String, Object?>{...environment.globals, ...?data},
        autoEscape = environment.autoEscape;

  final Environment environment;

  final Map<String, Object?>? parent;

  final Map<String, Object?> context;

  bool autoEscape;

  Object? call(dynamic object,
      [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    var function = object.call as Function;
    positional ??= <Object?>[];
    return Function.apply(function, positional, named);
  }

  Context derived() {
    return Context(environment, parent: context);
  }

  Object? escape(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Markup) {
      return value;
    }

    if (autoEscape) {
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

  Object? item(Object? value, Object? key) {
    return environment.getItem(value, key);
  }

  Object? attribute(Object? value, String key) {
    return environment.getAttribute(value, key);
  }

  Object? filter(
      String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callFilter(name, positional, named, this);
  }

  bool test(String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callTest(name, positional, named, this);
  }
}
