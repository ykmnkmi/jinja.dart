import 'environment.dart';
import 'markup.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, [Map<String, Object?>? data])
      : context = <String, Object?>{...environment.globals, ...?data} {
    context
      ..['context'] = this
      ..['ctx'] = this
      ..['environment'] = environment
      ..['env'] = environment
      ..['autoescape'] = environment.autoEscape;
  }

  Context.from(Context context)
      : environment = context.environment,
        context = Map<String, Object?>.of(context.context);

  final Environment environment;

  final Map<String, Object?> context;

  // TODO: remove
  bool get autoEscape {
    return resolve('autoescape') as bool;
  }

  Object? call(dynamic object,
      [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    positional ??= <Object?>[];
    return Function.apply(object.call as Function, positional, named);
  }

  Object? escape(Object? value, [bool escaped = false]) {
    if (value == null) {
      return null;
    }

    if (value is Markup) {
      return value;
    }

    if (autoEscape) {
      if (escaped) {
        return Markup.escaped(value);
      }

      return Markup.escape(value);
    }

    return value;
  }

  bool has(String key) {
    return context.containsKey(key);
  }

  Object? resolve(String key) {
    return context[key];
  }

  Object? filter(
      String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callFilter(name, positional, named, this);
  }

  bool test(String name, List<Object?> positional, Map<Symbol, Object?> named) {
    return environment.callTest(name, positional, named);
  }
}
