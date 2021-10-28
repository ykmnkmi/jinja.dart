import 'package:meta/meta.dart' show internal;

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

int count(dynamic iterable) {
  // if (iterable is Iterable) {
  //   return iterable.length;
  // }

  // if (iterable is String) {
  //   return iterable.length;
  // }

  // if (iterable is Map) {
  //   return iterable.length;
  // }

  // throw TypeError();
  return iterable.length as int;
}

List<Object?> list(Object? iterable) {
  if (iterable is List) {
    return iterable;
  }

  if (iterable is Iterable) {
    return iterable.toList();
  }

  if (iterable is String) {
    return iterable.split('');
  }

  if (iterable is Map) {
    return iterable.keys.toList();
  }

  throw TypeError();
}

class PassArgument {
  static const PassArgument context = PassArgument(0);

  static const PassArgument environment = PassArgument(1);

  @internal
  static final Expando<PassArgument> store = Expando<PassArgument>();

  @internal
  const PassArgument(this.value);

  final Object value;

  static PassArgument? getFrom(Function function) {
    return store[function];
  }
}

/// Pass the [Context] as the first argument to the function when
/// called while rendering a template.
Function passContext(Function function) {
  PassArgument.store[function] = PassArgument.context;
  return function;
}

/// Pass the [Environment] as the first argument to the function
/// when called while rendering a template.
Function passEnvironment(Function function) {
  PassArgument.store[function] = PassArgument.environment;
  return function;
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

  if (step < 0) {
    for (var i = start; i >= stop; i += step) {
      yield i;
    }
  } else {
    for (var i = start; i < stop; i += step) {
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
    var keys = object.keys.toList();
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
