import 'utils.dart' show getSymbolName;

/// The default undefined type.
class Undefined {
  const Undefined();

  @override
  String toString() {
    return '';
  }
}

const namespace = _NameSpaceFactory();

class NameSpace {
  NameSpace([Map<String, Object?>? data])
      : data =
            data != null ? Map<String, Object?>.of(data) : <String, Object?>{};

  final Map<String, Object?> data;

  Iterable<MapEntry<String, Object?>> get entries {
    return data.entries;
  }

  Object? operator [](String key) {
    return data[key];
  }

  void operator []=(String key, Object? value) {
    data[key] = value;
  }
}

// TODO: remove/improve workaround
class _NameSpaceFactory {
  const _NameSpaceFactory();

  NameSpace call() {
    return NameSpace();
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final data = <String, Object?>{};

      if (invocation.positionalArguments.length == 1) {
        final arg = invocation.positionalArguments.first;

        if (arg is Map<String, Object?>) {
          data.addAll(arg);
        } else if (arg is List) {
          for (final pair in arg) {
            if (pair is Map) {
              data.addAll(pair.map((a, b) => MapEntry(a.toString(), b)));
              continue;
            }

            List<Object?> list;

            if (pair is Iterable) {
              list = pair.toList();
            } else if (pair is String) {
              list = pair.split('');
            } else {
              throw ArgumentError('cannot convert map update sequence '
                  'element #${arg.indexOf(pair)} to a sequence');
            }

            if (list.length != 2) {
              throw ArgumentError(
                  'map update sequence element #${arg.indexOf(pair)}, '
                  'has length ${list.length}; 2 is required');
            }

            if (list[0] is String) {
              data[list[0] as String] = list[1];
            }
          }
        } else {
          // TODO: correct: error message
          throw TypeError();
        }
      } else if (invocation.positionalArguments.length > 1) {
        throw ArgumentError('map expected at most 1 arguments, '
            'got ${invocation.positionalArguments.length}');
      }

      invocation.namedArguments.forEach((key, value) {
        if (value is Map<Symbol, Object?>) {
          data.addAll(
              value.map((key, value) => MapEntry(getSymbolName(key), value)));
        } else {
          data.addEntries([MapEntry(getSymbolName(key), value)]);
        }
      });

      return NameSpace(data);
    }

    return super.noSuchMethod(invocation);
  }
}

class LoopContext {
  LoopContext(int index0, int length, Object? previtem, Object? nextitem,
      Function changed)
      : data = <String, Object?>{
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
          'cycle': _CycleWrapper((args) => args[index0 % args.length]),
        };

  final Map<String, Object?> data;

  Object? operator [](String key) {
    return data[key]!;
  }
}

// TODO: remove/improve workaround
class _CycleWrapper {
  _CycleWrapper(this.function);

  final Object? Function(List<Object?> values) function;

  Object? call();

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.positionalArguments[0] as List);
    }

    return super.noSuchMethod(invocation);
  }
}
