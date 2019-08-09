import 'environment.dart';

typedef ContextFn = void Function(Context context);

class Context {
  Context({
    Map<String, dynamic> context,
    Environment environment,
  })  : this.contexts = context != null ? [context] : [<String, dynamic>{}],
        this.environment = environment ?? Environment();

  final Environment environment;
  final List<Map<String, dynamic>> contexts;

  dynamic operator [](String key) {
    for (var context in contexts.reversed) {
      if (context.containsKey(key)) return context[key];
    }

    if (environment.globalContext.containsKey(key)) {
      return environment.globalContext[key];
    }

    return environment.undefined;
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
