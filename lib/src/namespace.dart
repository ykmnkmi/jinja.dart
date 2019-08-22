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
      final args = invocation.positionalArguments;

      if (args.isNotEmpty) {
        if (args.any((arg) => arg is Map<String, dynamic>)) {
          for (var arg in args.cast<Map<String, dynamic>>()) data.addAll(arg);
        } else {
          // TODO: update exception
          throw Exception();
        }
      }

      data.addAll(invocation.namedArguments
          .map((key, value) => MapEntry(MirrorSystem.getName(key), value)));
      return NameSpace(data);
    }

    return super.noSuchMethod(invocation);
  }
}
