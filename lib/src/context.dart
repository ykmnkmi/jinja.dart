import 'dart:collection';

import 'package:jinja/src/environment.dart';

base class Context {
  Context(
    this.environment, {
    this.parent = const <String, Object?>{},
    Map<String, Object?>? data,
  }) : context = HashMap<String, Object?>() {
    if (data != null) {
      context.addAll(data);
    }
  }

  final Environment environment;

  final Map<String, Object?> parent;

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
      // TODO(dynamic): dynamic invocation
      // ignore: avoid_dynamic_calls
      function = object.call as Function;
    }

    return environment.callCommon(function, positional, named, this);
  }

  Context derived({Map<String, Object?>? data}) {
    var parent = HashMap<String, Object?>.from(this.parent)..addAll(context);
    return Context(environment, parent: parent, data: data);
  }

  bool has(String key) {
    if (context.containsKey(key)) {
      return true;
    }

    return parent.containsKey(key);
  }

  Object? resolve(String key) {
    if (context.containsKey(key)) {
      return context[key];
    }

    if (parent.containsKey(key)) {
      return parent[key];
    }

    return environment.undefined?.call(key);
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
