import 'dart:collection' show HashMap, MapView;

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

class LoopContext extends Iterable<Object?> {
  LoopContext(this.values, this.depth0, this.recurse)
      : length = values.length,
        index0 = -1;

  final List<Object?> values;

  @override
  final int length;

  final String Function(Object? data, [int depth]) recurse;

  int index0;

  int depth0;

  @override
  LoopIterator get iterator {
    return LoopIterator(this);
  }

  int get index {
    return index0 + 1;
  }

  int get depth {
    return depth0 + 1;
  }

  int get revindex0 {
    return length - index;
  }

  int get revindex {
    return length - index0;
  }

  @override
  bool get first {
    return index0 == 0;
  }

  @override
  bool get last {
    return index == length;
  }

  Object? get next {
    if (!last) {
      return values[index0 + 1];
    }

    return null;
  }

  Object? get nextitem {
    return next;
  }

  Object? get prev {
    if (first) {
      return null;
    }

    return values[index0 - 1];
  }

  Object? get previtem {
    return prev;
  }

  Object? operator [](String key) {
    switch (key) {
      case 'length':
        return length;
      case 'index0':
        return index0;
      case 'depth0':
        return depth0;
      case 'index':
        return index;
      case 'depth':
        return depth;
      case 'revindex0':
        return revindex0;
      case 'revindex':
        return revindex;
      case 'first':
        return first;
      case 'last':
        return last;
      case 'prev':
        return prev;
      case 'previtem':
        return previtem;
      case 'next':
        return next;
      case 'nextitem':
        return nextitem;
      case 'call':
        return call;
      case 'cycle':
        return cycle;
      case 'changed':
        return changed;
      default:
        var invocation = Invocation.getter(Symbol(key));
        throw NoSuchMethodError.withInvocation(this, invocation);
    }
  }

  String call(Object? data) {
    return recurse(data, depth);
  }

  Object? cycle(Iterable<Object?> values, [Iterable<Object?>? packed]) {
    if (values.isEmpty && packed != null && packed.isEmpty) {
      throw TypeError();
    }

    if (packed != null) {
      values = values.followedBy(packed);
    }

    return values.elementAt(index0 % values.length);
  }

  bool changed(Object? item) {
    if (index0 == 0) {
      return true;
    }

    if (item == previtem) {
      return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'LoopContext()';
  }
}

class LoopIterator extends Iterator<Object?> {
  LoopIterator(this.context);

  final LoopContext context;

  @override
  Object? get current {
    return context.values[context.index0];
  }

  @override
  bool moveNext() {
    if (context.index < context.length) {
      context.index0 += 1;
      return true;
    }

    return false;
  }
}

class Cycler extends Iterable<Object?> {
  Cycler(List<Object?> values)
      : values = List<dynamic>.of(values),
        length = values.length,
        index = 0;

  final List<Object?> values;

  @override
  final int length;

  int index;

  Object? get current {
    return values[index];
  }

  @override
  Iterator<Object?> get iterator {
    return CyclerIterator(this);
  }

  Object? next() {
    var result = current;
    index = (index + 1) % length;
    return result;
  }

  void reset() {
    index = 0;
  }
}

class CyclerIterator extends Iterator<Object?> {
  CyclerIterator(this.cycler);

  final Cycler cycler;

  @override
  Object? current;

  @override
  bool moveNext() {
    current = cycler.next();
    return true;
  }
}
