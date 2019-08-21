import 'dart:mirrors';

class NameSpace {
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

class NameSpaceWrapper {
  const NameSpaceWrapper();

  NameSpace call() => NameSpace();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return NameSpace(invocation.namedArguments
          .map((key, value) => MapEntry(MirrorSystem.getName(key), value)));
    }

    return super.noSuchMethod(invocation);
  }
}
