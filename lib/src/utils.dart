import 'runtime.dart';

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield i;
  }
}

bool toBool(dynamic value) {
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

String repr(dynamic object, [bool reprString = true]) {
  if (object is Iterable) {
    final buffer = StringBuffer('[')
      ..writeAll(object.map(repr), ', ')
      ..write(']');
    return buffer.toString();
  } else if (object is Map) {
    final entries = object.entries
        .map((entry) => '${repr(entry.key)}: ${repr(entry.value)}');
    final buffer = StringBuffer('{')
      ..writeAll(entries, ', ')
      ..write('}');
    return buffer.toString();
  } else if (object is String && reprString) {
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
