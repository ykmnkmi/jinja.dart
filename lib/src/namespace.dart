class NameSpace {
  static NameSpace factory([Map<Object, Object> data]) => NameSpace(data);

  NameSpace([Map<Object, Object> data])
      : _data =
            data != null ? Map<Object, Object>.of(data) : <Object, Object>{};

  final Map<Object, Object> _data;
  Iterable<MapEntry<Object, Object>> get entries => _data.entries;

  Object operator [](Object key) => _data[key];

  void operator []=(Object key, Object value) {
    _data[key] = value;
  }

  NameSpace copy() => NameSpace(Map<Object, Object>.from(_data));
}
