import 'runtime.dart';

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield i;
  }
}

bool toBool(Object? value) {
  assert(value != null);

  if (value is Undefined || value == null) {
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

  if (value is Iterable) {
    return value.isNotEmpty;
  }

  if (value is Map) {
    return value.isNotEmpty;
  }

  return true;
}

String repr(Object? object) {
  assert(object != null);

  if (object is Iterable) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map(repr), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map) {
    final buffer = StringBuffer('{');
    final pairs = [];

    object.forEach((key, value) {
      pairs.add('${repr(key)}: ${repr(value)}');
    });

    buffer
      ..writeAll(pairs, ', ')
      ..write('}');
    return buffer.toString();
  } else if (object is String) {
    final string = object.replaceAll('\'', '\\\'');
    return "'$string'";
  } else {
    return object.toString();
  }
}

String getSymbolName(Symbol symbol) {
  final fullName = symbol.toString();
  return fullName.substring(8, fullName.length - 2);
}
