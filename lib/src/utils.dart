import 'runtime.dart';

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield i;
  }
}

bool toBool(Object? value) {
  if (value is Undefined || value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0.0;
  if (value is String) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

String repr(Object object, [bool reprString = true]) {
  if (object is Iterable<Object>) {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(object.map<String>(repr), ', ');
    buffer.write(']');
    return '$buffer';
  } else if (object is Map<Object, Object>) {
    final buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(object.entries.map<String>((entry) {
      final key = repr(entry.key);
      final value = repr(entry.value);
      return '$key: $value';
    }), ', ');
    buffer.write('}');
    return '$buffer';
  } else if (object is String && reprString) {
    final string = object.replaceAll('\'', '\\\'');
    return "'$string'";
  } else {
    return '$object';
  }
}

String getSymbolName(Symbol symbol) {
  final fullName = '$symbol';
  return fullName.substring(8, fullName.length - 2);
}
