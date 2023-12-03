import 'package:jinja/src/environment.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

base class Context {
  Context(this.environment, {this.parent, Map<String, Object?>? data})
      : context = <String, Object?>{...environment.globals, ...?data};

  final Environment environment;

  final Map<String, Object?>? parent;

  final Map<String, Object?> context;

  Object? call(
    dynamic object, [
    List<Object?> positional = const <Object?>[],
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
  ]) {
    Function function;

    if (object is Function) {
      function = object;
    } else {
      // TODO: dynamic invocation
      // ignore: avoid_dynamic_calls
      function = object.call as Function;
    }

    return environment.callCommon(function, positional, named, this);
  }

  Context derived({Map<String, Object?>? data}) {
    return Context(environment, parent: context, data: data);
  }

  bool has(String key) {
    if (context.containsKey(key)) {
      return true;
    }

    if (parent case var parent?) {
      return parent.containsKey(key);
    }

    return false;
  }

  Object? get(String key) {
    return context[key];
  }

  Object? resolve(String key) {
    if (context.containsKey(key)) {
      return context[key];
    }

    if (parent case var parent?) {
      return parent[key];
    }

    return null;
  }

  Object? attribute(String key, Object? value) {
    return environment.getAttribute(key, value);
  }

  Object? item(Object? key, Object? value) {
    return environment.getItem(key, value);
  }

  Object? filter(
    String name, [
    List<Object?> positional = const <Object?>[],
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
  ]) {
    return environment.callFilter(name, positional, named, this);
  }

  bool test(
    String name, [
    List<Object?> positional = const <Object?>[],
    Map<Symbol, Object?> named = const <Symbol, Object?>{},
  ]) {
    return environment.callTest(name, positional, named, this);
  }
}
