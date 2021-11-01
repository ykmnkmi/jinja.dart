import 'markup.dart';

bool isBoolean(Object? object) {
  return object is bool;
}

bool isCallable(Object? object) {
  // or try to get call method?
  return object is Function;
}

bool isDefined(Object? value) {
  return value != null;
}

bool isDivisibleBy(num value, num divider) {
  if (divider == 0) {
    return false;
  }

  return value % divider == 0;
}

bool isEqual(Object? value, Object? other) {
  return value == other;
}

bool isEscaped(Object? value) {
  return value is Markup;
}

bool isEven(int value) {
  return value.isEven;
}

bool isFalse(Object? value) {
  return value == false;
}

bool isFloat(Object? value) {
  return value is double;
}

bool isGreaterThanOrEqual(
    Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) >= 0;
}

bool isGreaterThan(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) > 0;
}

bool isIn(Object? value, Object? values) {
  if (values is String) {
    if (value is Pattern) {
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

bool isInteger(Object? value) {
  return value is int;
}

bool isIterable(Object? value) {
  return value is Iterable;
}

bool isLessThanOrEqual(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) <= 0;
}

bool isLessThan(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) < 0;
}

bool isLower(String value) {
  return value == value.toLowerCase();
}

bool isMapping(Object? value) {
  return value is Map;
}

bool isNotEqual(Object? value, Object? other) {
  return value != other;
}

bool isNull(Object? value) {
  return value == null;
}

bool isNumber(Object? object) {
  return object is num;
}

bool isOdd(int value) {
  return value.isOdd;
}

bool isSameAs(Object? value, Object? other) {
  return identical(value, other);
}

bool isSequence(Object? value) {
  return value is String || value is List || value is Map;
}

bool isString(Object? object) {
  return object is String;
}

bool isTrue(Object? value) {
  return value == true;
}

bool isUndefined(Object? value) {
  return value == null;
}

bool isUpper(String value) {
  return value == value.toUpperCase();
}

const Map<String, Function> tests = {
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
  'escaped': isEscaped,
  'even': isEven,
  'false': isFalse,
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
  'true': isTrue,
  'undefined': isNull,
  'upper': isUpper,
};
