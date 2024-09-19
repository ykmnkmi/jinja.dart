import 'package:jinja/src/environment.dart';

typedef ContextCallback = void Function(Context context);

base class Context {
  Context(
    this.environment, {
    this.template,
    Map<String, List<ContextCallback>>? blocks,
    this.parent = const <String, Object?>{},
    Map<String, Object?>? data,
  })  : blocks = blocks ?? <String, List<ContextCallback>>{},
        context = <String, Object?>{...?data};

  final Environment environment;

  String? template;

  final Map<String, List<ContextCallback>> blocks;

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

  Context derived({
    String? template,
    Map<String, Object?>? data,
  }) {
    return Context(
      environment,
      template: template ?? this.template,
      blocks: blocks,
      parent: parent,
      data: data,
    );
  }

  bool has(String key) {
    if (context.containsKey(key)) {
      return true;
    }

    return parent.containsKey(key);
  }

  Object? resolve(String name) {
    if (context.containsKey(name)) {
      return context[name];
    }

    if (parent.containsKey(name)) {
      return parent[name];
    }

    return environment.undefined(name, template);
  }

  void set(String key, Object? value) {
    context[key] = value;
  }

  bool remove(String name) {
    if (context.containsKey(name)) {
      context.remove(name);
      return true;
    }

    return false;
  }

  Object? undefined(String name, [String? template]) {
    return environment.undefined(name, template);
  }

  Object? attribute(String name, Object? value) {
    return environment.getAttribute(name, value);
  }

  Object? item(Object? name, Object? value) {
    return environment.getItem(name, value);
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

base class Namespace {
  Namespace([Map<String, Object?>? data])
      : context = <String, Object?>{...?data};

  final Map<String, Object?> context;

  Object? operator [](String name) {
    return context[name];
  }

  void operator []=(String name, Object? value) {
    context[name] = value;
  }

  static Namespace factory([List<Object?>? datas]) {
    var namespace = Namespace();

    if (datas == null) {
      return namespace;
    }

    for (var data in datas) {
      if (data is! Map) {
        // TODO(namespace): update error
        throw TypeError();
      }

      namespace.context.addAll(data.cast<String, Object?>());
    }

    return namespace;
  }
}

final class NamespaceValue {
  NamespaceValue(this.name, this.item);

  final String name;

  final String item;
}
