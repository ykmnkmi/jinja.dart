typedef Indices = Iterable<int> Function(int stopOrStart,
    [int? stop, int? step]);

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
    final result = current;
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

bool boolean(Object? value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0.0;
  }

  if (value is String) {
    return value.isNotEmpty;
  }

  if (value is Iterable<Object?>) {
    return value.isNotEmpty;
  }

  if (value is Map<Object?, Object?>) {
    return value.isNotEmpty;
  }

  return true;
}

String format(Object? object) {
  return repr(object);
}

List<Object?> list(Object? iterable) {
  if (iterable is Iterable) {
    return List<Object?>.of(iterable);
  }

  if (iterable is String) {
    return List<Object?>.of(iterable.split(''));
  }

  if (iterable is Map) {
    return List<Object?>.of(iterable.keys);
  }

  throw TypeError();
}

Iterable<int> range(int stopOrStart, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    throw StateError('range() argument 3 must not be zero');
  }

  int start;

  if (stop == null) {
    start = 0;
    stop = stopOrStart;
  } else {
    start = stopOrStart;
    stop = stop;
  }

  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      yield i;
    }
  } else {
    for (var i = start; i > stop; i += step) {
      yield i;
    }
  }
}

String repr(Object? object, [bool escapeNewlines = false]) {
  final buffer = StringBuffer();
  reprTo(object, buffer, escapeNewlines);
  return '$buffer';
}

void reprTo(Object? object, StringBuffer buffer,
    [bool escapeNewlines = false]) {
  if (object is String) {
    object = object.replaceAll("'", "\\'");

    if (escapeNewlines) {
      object = object.replaceAllMapped(RegExp('(\r\n|\r|\n)'), (match) {
        return match.group(1) ?? '';
      });
    }

    buffer.write('\'$object\'');
    return;
  }

  if (object is List<Object?>) {
    buffer.write('[');

    for (var i = 0; i < object.length; i += 1) {
      if (i > 0) {
        buffer.write(', ');
      }

      reprTo(object[i], buffer);
    }

    buffer.write(']');
    return;
  }

  if (object is Map<Object?, Object?>) {
    final keys = object.keys.toList();
    buffer.write('{');

    for (var i = 0; i < keys.length; i += 1) {
      if (i > 0) {
        buffer.write(', ');
      }

      reprTo(keys[i], buffer);
      buffer.write(': ');
      reprTo(object[keys[i]], buffer);
    }

    buffer.write('}');
    return;
  }

  buffer.write(object);
}

Object slice(Object value, Indices indices) {
  if (value is String) {
    return sliceString(value, indices);
  }

  if (value is List<Object?>) {
    return sliceList<Object?>(value, indices);
  }

  throw TypeError();
}

List<T> sliceList<T>(List<T> list, Indices indices) {
  final result = <T>[];

  for (final i in indices(list.length)) {
    result.add(list[i]);
  }

  return result;
}

String sliceString(String string, Indices indices) {
  final buffer = StringBuffer();

  for (final i in indices(string.length)) {
    buffer.write(string[i]);
  }

  return '$buffer';
}
