import 'runtime.dart';

Iterable<int> range(int n) sync* {
  for (int i = 0; i < n; i++) {
    yield i;
  }
}

bool toBool(Object value) {
  if (value is Undefined || value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0.0;
  if (value is String) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

String repr(Object object, [bool reprString = true]) {
  if (object is Iterable) {
    StringBuffer buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(object.map<Object>(repr), ', ');
    buffer.write(']');
    return buffer.toString();
  } else if (object is Map) {
    StringBuffer buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(
        object.entries.map<Object>((MapEntry<Object, Object> entry) =>
            '${repr(entry.key)}: ${repr(entry.value)}'),
        ', ');
    buffer.write('}');
    return buffer.toString();
  } else if (reprString && object is String) {
    return '\'${object.replaceAll('\'', '\\\'').replaceAll('\n', '\\n')}\'';
  } else {
    return object.toString();
  }
}

String getSymbolName(Symbol symbol) {
  String fullName = symbol.toString();
  return fullName.substring(8, fullName.length - 2);
}
