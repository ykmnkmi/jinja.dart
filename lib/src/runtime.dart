import 'utils.dart' show getSymbolName;

/// The default undefined type.
class Undefined {
  const Undefined();

  @override
  String toString() => '';
}

class NameSpace {
  static final Function namespace = NameSpaceFactory();

  NameSpace([Map<String, Object> data])
      : data = data != null ? Map<String, Object>.of(data) : <String, Object>{};

  final Map<String, Object> data;

  Iterable<MapEntry<String, Object>> get entries {
    return data.entries;
  }

  Object operator [](String key) {
    return data[key];
  }

  void operator []=(String key, Object value) {
    data[key] = value;
  }

  @override
  Object noSuchMethod(Invocation invocation) {
    var name = invocation.memberName.toString();

    if (invocation.isSetter) {
      // 'name='
      name = name.substring(0, name.length - 1);
      data[name] = invocation.positionalArguments.first;
      return null;
    }

    if (data.containsKey(name)) {
      if (invocation.isGetter) return data[name];

      if (invocation.isMethod) {
        return Function.apply(data[name] as Function,
            invocation.positionalArguments, invocation.namedArguments);
      }
    }

    return super.noSuchMethod(invocation);
  }
}

// TODO: убрать костыль
// ignore: deprecated_extends_function
class NameSpaceFactory extends Function {
  NameSpace call() {
    return NameSpace();
  }

  @override
  Object noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final data = <String, Object>{};

      if (invocation.positionalArguments.length == 1) {
        final Object arg = invocation.positionalArguments.first;

        if (arg is Map<String, Object>) {
          data.addAll(arg);
        } else if (arg is List<Object>) {
          for (var pair in arg) {
            List<Object> list;

            if (pair is Iterable<Object>) {
              list = pair.toList();
            } else if (pair is String) {
              list = pair.split('');
            } else {
              throw ArgumentError('cannot convert map update sequence '
                  'element #${arg.indexOf(pair)} to a sequence');
            }

            if (list.length < 2 || list.length > 2) {
              throw ArgumentError(
                  'map update sequence element #${arg.indexOf(pair)}, '
                  'has length ${list.length}; 2 is required');
            }

            if (list[0] is String) {
              data[list[0] as String] = list[1];
            }
          }
        } else {
          // TODO: поправить: текст ошибки
          throw TypeError();
        }
      } else if (invocation.positionalArguments.length > 1) {
        throw ArgumentError('map expected at most 1 arguments, '
            'got ${invocation.positionalArguments.length}');
      }

      data.addAll(invocation.namedArguments.map<String, Object>(
          (Symbol key, Object value) =>
              MapEntry<String, Object>(getSymbolName(key), value)));
      return NameSpace(data);
    }

    return super.noSuchMethod(invocation);
  }
}

class LoopContext {
  LoopContext(int index0, int length, Object previtem, Object nextitem,
      Function changed)
      : data = <String, Object>{
          'index0': index0,
          'length': length,
          'previtem': previtem,
          'nextitem': nextitem,
          'changed': changed,
          'index': index0 + 1,
          'first': index0 == 0,
          'last': index0 + 1 == length,
          'revindex': length - index0,
          'revindex0': length - index0 - 1,
          'cycle':
              CycleWrapper((List<Object> args) => args[index0 % args.length]),
        };

  final Map<String, Object> data;

  Object operator [](String key) {
    return data[key];
  }
}

// TODO: убрать костыль
// ignore: deprecated_extends_function
class CycleWrapper extends Function {
  CycleWrapper(this.function);

  final Object Function(List<Object> values) function;

  Object call();

  @override
  Object noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}
