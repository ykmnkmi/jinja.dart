import 'environment.dart';
import 'nodes.dart';

typedef ContextCallback = void Function(Context context);

class Context {
  Context(this.environment, [Map<String, Object?>? data])
      : contexts = <Map<String, Object?>>[data ?? <String, Object?>{}],
        blockContext = ExtendedBlockContext();

  final Environment environment;

  final List<Map<String, Object?>> contexts;

  final ExtendedBlockContext blockContext;

  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
  }

  bool removeLast(String name) {
    for (final context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  Object? operator [](String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    if (environment.globals.containsKey(key)) {
      return environment.globals[key];
    }

    return environment.undefined;
  }

  void operator []=(String key, Object? value) {
    contexts.last[key] = value;
  }

  void push(Map<String, Object?> context) {
    contexts.add(context);
  }

  void pop() {
    contexts.removeLast();
  }

  void apply(Map<String, Object?> data, ContextCallback closure) {
    push(data);

    try {
      closure(this);
    } finally {
      pop();
    }
  }
}
