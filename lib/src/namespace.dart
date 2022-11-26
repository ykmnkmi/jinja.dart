import 'dart:collection';

class Namespace extends MapView<String, Object?> {
  Namespace([Map<String, Object?>? context])
      : super(HashMap<String, Object?>()) {
    if (context != null) {
      addAll(context);
    }
  }

  @override
  String toString() {
    var values = entries.map((entry) => '${entry.key}: ${entry.value}');
    return 'Namespace(${values.join(', ')})';
  }

  static Namespace factory([List<Object?>? datas]) {
    var namespace = Namespace();

    if (datas == null) {
      return namespace;
    }

    for (var data in datas) {
      if (data is! Map) {
        // TODO: update error
        throw TypeError();
      }

      namespace.addAll(data.cast<String, Object?>());
    }

    return namespace;
  }
}

class NamespaceValue {
  NamespaceValue(this.name, this.item);

  String name;

  String item;

  @override
  String toString() {
    return 'NamespaceValue($name, $item)';
  }
}
