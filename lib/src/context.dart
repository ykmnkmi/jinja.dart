import 'environment.dart';
import 'nodes.dart';

typedef ContextFn = void Function(Context context);

class Context {
  Context({Map<String, Object>? data, Environment? env})
      : contexts = data != null
            ? <Map<String, Object>>[data]
            : <Map<String, Object>>[<String, Object>{}],
        environment = env ?? Environment(),
        blockContext = ExtendedBlockContext();

  final Environment environment;
  final List<Map<String, Object>> contexts;
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

  void operator []=(String key, Object value) {
    contexts.last[key] = value;
  }

  void push(Map<String, Object> context) {
    contexts.add(context);
  }

  void pop() {
    contexts.removeLast();
  }

  void apply(Map<String, Object> data, ContextFn closure) {
    push(data);

    try {
      closure(this);
    } finally {
      pop();
    }
  }
}
