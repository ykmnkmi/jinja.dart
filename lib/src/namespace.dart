import 'dart:mirrors';

class NameSpace {
  static const NameSpaceFactory Factory = const NameSpaceFactory();

  NameSpace([Map<String, dynamic> data])
      : _data = data != null ? Map.of(data) : <String, dynamic>{};

  final Map<String, dynamic> _data;
  Iterable<MapEntry<String, dynamic>> get entries => _data.entries;

  dynamic operator [](String key) => _data[key];

  void operator []=(String key, dynamic value) {
    _data[key] = value;
  }

  NameSpace copy() => NameSpace(Map.from(_data));

  @override
  dynamic noSuchMethod(Invocation invocation) {
    var name = MirrorSystem.getName(invocation.memberName);

    if (invocation.isSetter) {
      // 'name='
      name = name.substring(0, name.length - 1);
      _data[name] = invocation.positionalArguments.first;
      return null;
    }

    if (_data.containsKey(name)) {
      if (invocation.isGetter) return _data[name];

      if (invocation.isMethod) {
        return Function.apply(_data[name].call as Function,
            invocation.positionalArguments, invocation.namedArguments);
      }
    }

    return super.noSuchMethod(invocation);
  }
}

class NameSpaceFactory {
  const NameSpaceFactory();

  NameSpace call() => NameSpace();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      final data = <String, Object>{};

      if (invocation.positionalArguments.length == 1) {
        final arg = invocation.positionalArguments.first;

        if (arg is Map<String, dynamic>) {
          data.addAll(arg);
        } else if (arg is List) {
          for (var i = 0, pair = arg[i]; i < arg.length; i++) {
            List list;

            if (pair is Iterable) {
              list = pair.toList(growable: false);
            } else if (pair is String) {
              list = pair.split('');
            } else {
              throw ArgumentError('cannot convert map update sequence '
                  'element #$i to a sequence');
            }

            if (list.length < 2 || list.length > 2) {
              throw ArgumentError('map update sequence element #$i, '
                  'has length ${list.length}; 2 is required');
            }

            if (list[0] is String) data[list[0] as String] = list[1];
          }
        } else {
          throw TypeError();
        }
      } else if (invocation.positionalArguments.length > 1) {
        throw ArgumentError('map expected at most 1 arguments, '
            'got ${invocation.positionalArguments.length}');
      }

      data.addAll(invocation.namedArguments
          .map((key, value) => MapEntry(MirrorSystem.getName(key), value)));
      return NameSpace(data);
    }

    return super.noSuchMethod(invocation);
  }
}
