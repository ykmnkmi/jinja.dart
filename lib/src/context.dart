import 'environment.dart';
import 'nodes.dart';

typedef ContextFn = void Function(Context context);

class Context {
  Context({
    Map<String, dynamic> data,
    Environment env,
  })  : contexts = data != null ? [data] : [<String, dynamic>{}],
        env = env ?? Environment(),
        blockContext = ExtendedBlockContext();

  final Environment env;
  final List<Map<String, dynamic>> contexts;
  final ExtendedBlockContext blockContext;

  bool has(String name) => contexts.any((context) => context.containsKey(name));

  bool removeLast(String name) {
    for (var context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  dynamic operator [](String key) {
    for (var context in contexts.reversed) {
      if (context.containsKey(key)) return context[key];
    }

    if (env.globalContext.containsKey(key)) {
      return env.globalContext[key];
    }

    return env.undefined;
  }

  void operator []=(String key, dynamic value) {
    contexts.last[key] = value;
  }

  void push([Map<String, dynamic> context = const <String, dynamic>{}]) {
    contexts.add(context);
  }

  Map<String, dynamic> pop() => contexts.removeLast();

  void apply(Map<String, dynamic> data, ContextFn closure) {
    push(data);

    try {
      closure(this);
    } finally {
      pop();
    }
  }
}
