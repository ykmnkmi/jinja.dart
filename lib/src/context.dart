import 'environment.dart';
import 'nodes.dart';

typedef ContextCallback = void Function(Context context);

class Context {
  Context(this.environment, [Map<String, dynamic>? data])
      : contexts = <Map<String, dynamic>>[data ?? <String, dynamic>{}],
        blockContext = ExtendedBlockContext();

  final Environment environment;

  final List<Map<String, dynamic>> contexts;

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

  dynamic operator [](String key) {
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

  void operator []=(String key, dynamic value) {
    contexts.last[key] = value;
  }

  void push(Map<String, dynamic> context) {
    contexts.add(context);
  }

  void pop() {
    contexts.removeLast();
  }

  void apply(Map<String, dynamic> data, ContextCallback closure) {
    push(data);

    try {
      closure(this);
    } finally {
      pop();
    }
  }
}
