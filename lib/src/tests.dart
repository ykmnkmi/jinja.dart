import 'environment.dart';

// TODO(doc): add
final Map<String, Function> tests = <String, Function>{
  '!=': isNotEqual,
  '<': isLessThan,
  '<=': isLessThanOrEqual,
  '==': isEqual,
  '>': isGreaterThan,
  '>=': isGreaterThanOrEqual,
  'boolean': isBoolean,
  'callable': isCallable,
  'defined': isDefined,
  'divisibleby': isDivisibleBy,
  'eq': isEqual,
  'equalto': isEqual,
  'even': isEven,
  'false': isFalse,
  'filter': passEnvironment(isFilter),
  'float': isFloat,
  'ge': isGreaterThanOrEqual,
  'greaterthan': isGreaterThan,
  'gt': isGreaterThan,
  'in': isIn,
  'integer': isInteger,
  'iterable': isIterable,
  'le': isLessThanOrEqual,
  'lessthan': isLessThan,
  'lower': isLower,
  'lt': isLessThan,
  'mapping': isMapping,
  'ne': isNotEqual,
  'none': isNull,
  'number': isNumber,
  'odd': isOdd,
  'sameas': isSameAs,
  'sequence': isSequence,
  'string': isString,
  'test': passEnvironment(isTest),
  'true': isTrue,
  'undefined': isUndefined,
  'upper': isUpper,
};

/// Return `true` if the object is a [bool].
bool isBoolean(Object? object) {
  return object is bool;
}

/// Return whether the object is callable (i.e., some kind of function).
/// Note that classes are callable, as are instances of classes with
/// a `call()` method.
bool isCallable(dynamic object) {
  if (object is Function) {
    return true;
  }

  try {
    object.call;
    return true;
  } on NoSuchMethodError {
    return false;
  }
}

/// Return `true` if the variable is not `null`
bool isDefined(Object? value) {
  return value != null;
}

/// Check if a variable is divisible by a number.
bool isDivisibleBy(num value, num divider) {
  return divider == 0 ? false : value % divider == 0;
}

/// Same as `a == b`.
bool isEqual(Object? value, Object? other) {
  return value == other;
}

/// Return `true` if the variable is even.
bool isEven(int value) {
  return value.isEven;
}

/// Return `true` if the object is `false`.
bool isFalse(Object? value) {
  return value == false;
}

/// Check if a filter exists by name. Useful if a filter may be
/// optionally available.
bool isFilter(Environment environment, String name) {
  return environment.filters.containsKey(name);
}

/// Return `true` if the object is a [double].
bool isFloat(Object? value) {
  return value is double;
}

/// Same as `a > b`.
bool isGreaterThan(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) > 0;
}

/// Same as `a >= b`.
bool isGreaterThanOrEqual(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) >= 0;
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

/// Return `true` if the object is an [int].
bool isInteger(Object? value) {
  return value is int;
}

/// Check if it's possible to iterate over an object.
bool isIterable(Object? object) {
  return object is Iterable;

  // try {
  //   value.iterator;
  //   return true;
  // } on NoSuchMethodError {
  //   return false;
  // }
}

/// Same as `a < b`.
bool isLessThan(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) < 0;
}

/// Same as `a <= b`.
bool isLessThanOrEqual(Object? value, Object? other) {
  return (value as Comparable<Object?>).compareTo(other) <= 0;
}

/// Return `true` if the variable is lowercased.
bool isLower(String value) {
  return value == value.toLowerCase();
}

/// Return `true` if the object is a [Map].
bool isMapping(Object? value) {
  return value is Map;
}

/// Same as `a != b`.
bool isNotEqual(Object? value, Object? other) {
  return value != other;
}

/// Return `true` if the variable is `null` (`none`).
bool isNull(Object? value) {
  return value == null;
}

/// Return `true` if the variable is a number.
bool isNumber(Object? value) {
  return value is num;
}

/// Return `true` if the variable is odd.
bool isOdd(int value) {
  return value.isOdd;
}

/// Check whether two references are to the same object.
bool isSameAs(Object? value, Object? other) {
  return identical(value, other);
}

/// Return `true` if the object is a sequence.
bool isSequence(Object? object) {
  return object is List || object is Map || object is String;

  // try {
  //   object.length;
  //   object[0];
  //   return true;
  // } on NoSuchMethodError {
  //   return false;
  // }
}

/// Return `true` if the object is a [String].
bool isString(Object? value) {
  return value is String;
}

/// Check if a test exists by name. Useful if a test may be
/// optionally available.
bool isTest(Environment environment, String name) {
  return environment.tests.containsKey(name);
}

/// Return `true` if the object is `true`.
bool isTrue(Object? value) {
  return value == true;
}

/// Like `defined()` but the other way round.
bool isUndefined(Object? value) {
  return value == null;
}

/// Return `true` if the variable is uppercased.
bool isUpper(String value) {
  return value == value.toUpperCase();
}
