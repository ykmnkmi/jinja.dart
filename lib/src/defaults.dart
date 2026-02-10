import 'package:jinja/src/runtime.dart';
import 'package:jinja/src/utils.dart';

export 'package:jinja/src/filters.dart' show filters;
export 'package:jinja/src/tests.dart' show tests;

const Map<String, Object?> globals = <String, Object?>{
  'namespace': Namespace.factory,
  'list': list,
  'print': print,
  'range': range,
};

Object finalize(Context context, Object? value) {
  return value ?? '';
}

Object? getItem(Object? item, dynamic object) {
  if (object is List) {
    if (item is int) {
      if (item < 0) {
        item = object.length + item;
      }

      if (item < 0 || item >= object.length) {
        return null;
      }
    }

    return (object as dynamic)[item];
  }

  if (object is String) {
    if (item == 'split') {
      return (Object? separator, [Object? limit]) {
        if (separator is String) {
          return object.split(separator);
        }
        return object.split(RegExp(r'\s+'));
      };
    }
  }

  try {
    // TODO(dynamic): dynamic invocation
    // ignore: avoid_dynamic_calls
    return object[item];
  } on NoSuchMethodError {
    if (object == null) {
      rethrow;
    }

    return null;
  } on RangeError {
    return null;
  }
}

Object? undefined(String name, [String? template]) {
  return null;
}
