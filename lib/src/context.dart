import 'environment.dart';
import 'nodes.dart';

typedef ContextFn = void Function(Context context);

class Context {
  Context({
    Map<String, Object> data,
    Environment env,
  })  : contexts = data != null ? <Map<String, Object>>[data] : <Map<String, Object>>[<String, Object>{}],
        env = env ?? Environment(),
        blockContext = ExtendedBlockContext();

  final Environment env;
  final List<Map<String, Object>> contexts;
  final ExtendedBlockContext blockContext;

  bool has(String name) => contexts.any((Map<String, Object> context) => context.containsKey(name));

  bool removeLast(String name) {
    for (Map<String, Object> context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  Object operator [](String key) {
    for (Map<String, Object> context in contexts.reversed) {
      if (context.containsKey(key)) return context[key];
    }

    if (env.globals.containsKey(key)) {
      return env.globals[key];
    }

    return env.undefined;
  }

  void operator []=(String key, Object value) {
    contexts.last[key] = value;
  }

  void push([Map<String, Object> context = const <String, Object>{}]) {
    contexts.add(context);
  }

  Map<String, Object> pop() => contexts.removeLast();

  void apply(Map<String, Object> data, ContextFn closure) {
    push(data);

    try {
      closure(this);
    } finally {
      pop();
    }
  }
}
