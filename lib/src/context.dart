import 'environment.dart';
import 'markup.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, [Map<String, Object?>? data])
      : contexts = <Map<String, Object?>>[
          environment.globals,
          <String, Object?>{...?data}
        ],
        minimal = 2 {
    contexts[1]
      ..['context'] = this
      ..['ctx'] = this
      ..['environment'] = environment
      ..['env'] = environment
      ..['autoescape'] = environment.autoEscape;
  }

  Context.from(Context context)
      : environment = context.environment,
        contexts = context.contexts,
        minimal = context.contexts.length;

  final Environment environment;

  final List<Map<String, Object?>> contexts;

  final int minimal;

  bool get autoEscape {
    return resolve('autoescape') as bool;
  }

  Object? call(dynamic object,
      [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    positional ??= <Object?>[];
    return Function.apply(object.call as Function, positional, named);
  }

  Object? escape(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Markup) {
      return value;
    }

    return autoEscape ? Markup(value) : value;
  }

  Object? escaped(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Markup) {
      return value;
    }

    return autoEscape ? Escaped(value) : value;
  }

  bool has(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  void pop() {
    if (contexts.length > minimal) {
      contexts.removeLast();
    }
  }

  void push(Map<String, Object?> context) {
    contexts.add(context);
  }

  Object? resolve(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return null;
  }
}
