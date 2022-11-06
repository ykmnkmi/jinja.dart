import 'package:jinja/src/environment.dart';
import 'package:jinja/src/markup.dart';

/// Return `true` if the variable is odd.
bool isOdd(int value) {
  return value.isOdd;
}

/// Return `true` if the variable is even.
bool isEven(int value) {
  return value.isEven;
}

/// Check if a variable is divisible by a number.
bool isDivisibleBy(num value, num divider) {
  return divider == 0 ? false : value % divider == 0;
}

/// Return `true` if the variable is not `null`.
bool isDefined(Object? value) {
  return value != null;
}

/// Like `defined()` but the other way round.
bool isUndefined(Object? value) {
  return value == null;
}

/// Check if a filter exists by name. Useful if a filter may be
/// optionally available.
bool isFilter(Environment environment, String name) {
  return environment.filters.containsKey(name);
}

/// Check if a test exists by name. Useful if a test may be
/// optionally available.
bool isTest(Environment environment, String name) {
  return environment.tests.containsKey(name);
}

/// Return `true` if the variable is `null` (`none`).
bool isNull(Object? value) {
  return value == null;
}

/// Return `true` if the object is a [bool].
bool isBoolean(Object? object) {
  return object is bool;
}

/// Return `true` if the object is `false`.
bool isFalse(Object? value) {
  return value == false;
}

/// Return `true` if the object is `true`.
bool isTrue(Object? value) {
  return value == true;
}

/// Return `true` if the object is an [int].
bool isInteger(Object? value) {
  return value is int;
}

/// Return `true` if the object is a [double].
bool isFloat(Object? value) {
  return value is double;
}

/// Return `true` if the variable is lowercased.
bool isLower(String value) {
  return value == value.toLowerCase();
}

/// Return `true` if the variable is uppercased.
bool isUpper(String value) {
  return value == value.toUpperCase();
}

/// Return `true` if the object is a [String].
bool isString(Object? value) {
  return value is String;
}

/// Return `true` if the object is a [Map].
bool isMap(Object? value) {
  return value is Map;
}

/// Return `true` if the variable is a [num].
bool isNumber(Object? value) {
  return value is num;
}

/// Return `true` if the object is a [List].
bool isList(Object? object) {
  return object is List;
}

/// Check whether two references are to the same object.
bool isSameAs(Object? value, Object? other) {
  return identical(value, other);
}

/// Return `true` if the object is a [Iterable].
bool isIterable(Object? object) {
  return object is Iterable;
}

/// Check if the value is escaped.
bool isEscaped(Object? value) {
  return value is Markup;
}

/// Check if value is in sequence.
bool isIn(Object? value, Object? values) {
  if (values is String) {
    if (value is String) {
      return values.contains(value);
    }

    throw TypeError();
  }

  if (values is Iterable) {
    return values.contains(value);
  }

  if (values is Map) {
    return values.containsKey(value);
  }

  throw TypeError();
}

/// Same as `a != b`.
bool isNotEqual(Object? value, Object? other) {
  return value != other;
}

/// Same as `a < b`.
bool isLessThan(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) < 0;
}

/// Same as `a <= b`.
bool isLessThanOrEqual(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) <= 0;
}

/// Same as `a == b`.
bool isEqual(Object? value, Object? other) {
  return value == other;
}

/// Same as `a > b`.
bool isGreaterThan(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) > 0;
}

/// Same as `a >= b`.
bool isGreaterThanOrEqual(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) >= 0;
}

/// Return whether the object is callable (i.e., some kind of function).
/// Note that classes are callable, as are instances of classes with
/// a `call()` method.
bool isCallable(dynamic object) {
  if (object is Function) {
    return true;
  }

  try {
    // TODO: dynamic invocation
    // ignore: avoid_dynamic_calls
    return object.call is Function;
  } on NoSuchMethodError {
    return false;
  }
}

final Map<String, Function> tests = <String, Function>{
  'odd': isOdd,
  'even': isEven,
  'divisibleby': isDivisibleBy,
  'defined': isDefined,
  'undefined': isUndefined,
  'filter': passEnvironment(isFilter),
  'test': passEnvironment(isTest),
  'none': isNull,
  'boolean': isBoolean,
  'false': isFalse,
  'true': isTrue,
  'integer': isInteger,
  'float': isFloat,
  'lower': isLower,
  'upper': isUpper,
  'string': isString,
  'map': isMap,
  'number': isNumber,
  'list': isList,
  'sameas': isSameAs,
  'iterable': isIterable,
  'escaped': isEscaped,
  'in': isIn,
  '!=': isNotEqual,
  '<': isLessThan,
  '<=': isLessThanOrEqual,
  '==': isEqual,
  '>': isGreaterThan,
  '>=': isGreaterThanOrEqual,
  'callable': isCallable,
  'eq': isEqual,
  'equalto': isEqual,
  'ge': isGreaterThanOrEqual,
  'greaterthan': isGreaterThan,
  'gt': isGreaterThan,
  'le': isLessThanOrEqual,
  'lessthan': isLessThan,
  'lt': isLessThan,
  'ne': isNotEqual,
};
