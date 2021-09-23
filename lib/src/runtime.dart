import 'dart:collection' show MapView;

export 'context.dart';

class LoopContext extends Iterable<Object?> {
  LoopContext(this.values, {this.depth0 = 0, this.recurse})
      : length = values.length,
        index0 = -1;

  final List<Object?> values;

  @override
  final int length;

  final String Function(Object? data, [int depth])? recurse;

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

  Object? get nextitem {
    if (!last) {
      return values[index0 + 1];
    }

    return null;
  }

  Object? get previtem {
    if (first) {
      return null;
    }

    return values[index0 - 1];
  }

  String call(Object? data) {
    if (recurse == null) {
      throw TypeError(
          /* the loop must have the 'recursive' marker to be called recursively. */);
    }

    return recurse!(data, depth);
  }

  Object cycle([Object? arg01, Object? arg02, Object? arg03]) {
    final values = <Object>[];

    if (arg01 != null) {
      values.add(arg01);

      if (arg02 != null) {
        values.add(arg02);

        if (arg03 != null) {
          values.add(arg03);
        }
      }
    }

    if (values.isEmpty) {
      throw TypeError();
    }

    return values[index0 % values.length];
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
      case 'previtem':
        return previtem;
      case 'nextitem':
        return nextitem;
      case 'call':
        return call;
      case 'cycle':
        return cycle;
      case 'changed':
        return changed;
      default:
        final invocation = Invocation.getter(Symbol(key));
        throw NoSuchMethodError.withInvocation(this, invocation);
    }
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

class Namespace extends MapView<String, Object?> {
  Namespace([Map<String, Object?>? context]) : super(<String, Object?>{}) {
    if (context != null) {
      addAll(context);
    }
  }

  @override
  String toString() {
    final values = entries.map((entry) => '${entry.key}: ${entry.value}');
    return 'Namespace(${values.join(', ')})';
  }

  static Namespace factory([List<Object?>? datas]) {
    final namespace = Namespace();

    if (datas == null) {
      return namespace;
    }

    for (final data in datas) {
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
    return 'NameSpaceValue($name, $item)';
  }
}
