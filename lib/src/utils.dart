import 'dart:mirrors';

import 'undefined.dart';

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) yield i;
}

dynamic tryGetField(dynamic value, dynamic field) {
  try {
    return reflect(value)
        .getField(field is Symbol ? field : Symbol('$field'))
        .reflectee;
  } catch (_) {
    return null;
  }
}

dynamic tryGetItem(dynamic value, dynamic key) {
  try {
    return value[key];
  } catch (_) {
    return null;
  }
}

bool toBool(dynamic value) {
  if (value is Undefined || value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0.0;
  if (value is String) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

String repr(dynamic object, [bool reprString = true]) {
  if (object is Iterable) {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.write(object.map((item) => repr(item)).join(', '));
    buffer.write(']');
    return buffer.toString();
  } else if (object is Map) {
    final buffer = StringBuffer();
    buffer.write('{');
    buffer.write(object.entries
        .map((entry) => '${repr(entry.key)}: ${repr(entry.value)}')
        .join(', '));
    buffer.write('}');
    return buffer.toString();
  } else if (reprString && object is String) {
    return '\'${object.replaceAll('\'', '\\\'').replaceAll('\n', '\\n')}\'';
  } else {
    return object.toString();
  }
}
