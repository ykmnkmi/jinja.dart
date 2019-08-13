import 'dart:mirrors';

class NameSpace {
  NameSpace([Map<String, dynamic> data]) : data = data ?? <String, dynamic>{};

  final Map<String, dynamic> data;

  dynamic operator [](String key) => data[key];

  void operator []=(String key, dynamic value) {
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    var name = MirrorSystem.getName(invocation.memberName);

    if (invocation.isSetter) {
      name = name.substring(0, name.length - 1);
      data[name] = invocation.positionalArguments.first;
      return null;
    }

    if (data.containsKey(name)) {
      if (invocation.isGetter) return data[name];

      if (invocation.isMethod) {
        return Function.apply(data[name].call as Function,
            invocation.positionalArguments, invocation.namedArguments);
      }
    }

    return super.noSuchMethod(invocation);
  }
}
