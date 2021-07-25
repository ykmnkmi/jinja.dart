import 'environment.dart';
import 'markup.dart';
import 'utils.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, [Map<String, Object?>? data])
      : contexts = <Map<String, Object?>>[environment.globals],
        minimal = 2 {
    data = data == null ? <String, Object?>{} : Map<String, Object?>.of(data);
    contexts.add(data);

    data
      ..['context'] = this
      ..['ctx'] = this
      ..['environment'] = this
      ..['env'] = this
      ..['autoescape'] = environment.autoEscape;
  }

  Context.from(Context context)
      : environment = context.environment,
        contexts = context.contexts,
        minimal = context.contexts.length;

  final Environment environment;

  final List<Map<String, Object?>> contexts;

  final int minimal;

  Object? operator [](String key) {
    return resolve(key);
  }

  void apply<C extends Context>(
      Map<String, Object?> data, ContextCallback<C> closure) {
    push(data);
    closure(this as C);
    pop();
  }

  Object? call(Object? object,
      [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    positional ??= <Object?>[];

    if (object is! Function) {
      object = environment.getAttribute(object, 'call');
    }

    if (object is Function) {
      return Function.apply(object, positional, named);
    }
  }

  Object? escape(Object? value) {
    return value != null && value is! Markup && boolean(get('autoescape'))
        ? Markup(value as String)
        : value;
  }

  Object? escaped(Object? value) {
    return value != null && value is! Markup && boolean(get('autoescape'))
        ? Markup.escaped(value)
        : value;
  }

  Object? get(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return missing;
  }

  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
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
    final result = get(key);

    if (result == missing) {
      return environment.undefined(name: key);
    }

    return result;
  }
}
