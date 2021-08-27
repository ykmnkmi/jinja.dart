import 'markup.dart';

bool isBoolean(Object? object) {
  return object is bool;
}

bool isCallable(Object? object) {
  return object is Function;
}

bool isDefined(Object? value) {
  return value != null;
}

bool isDivisibleBy(num value, num divider) {
  return divider == 0 ? false : value % divider == 0;
}

bool isEqual(Object? value, Object? other) {
  return value == other;
}

bool isEscaped(Object? value) {
  if (value is Markup) {
    return true;
  }

  return false;
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

bool isGreaterThanOrEqual(Object? value, Object? other) {
  return (value as dynamic >= other) as bool;
}

bool isGreaterThan(Object? value, Object? other) {
  return (value as dynamic > other) as bool;
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

  return (values as dynamic).contains(value) as bool;
}

bool isInteger(Object? value) {
  return value is int;
}

bool isIterable(Object? value) {
  if (value is Iterable) {
    return true;
  }

  return false;
}

bool isLessThanOrEqual(Object? value, Object? other) {
  return (value as dynamic <= other) as bool;
}

bool isLessThan(Object? value, Object? other) {
  return (value as dynamic < other) as bool;
}

bool isLower(String value) {
  return value == value.toLowerCase();
}

bool isMapping(Object? value) {
  if (value is Map) {
    return true;
  }

  return false;
}

bool isNone(Object? value) {
  if (value == null) {
    return true;
  }

  return false;
}

bool isNotEqual(Object? value, Object? other) {
  return value != other;
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
  try {
    (value as dynamic).length;
    (value as dynamic)[0];
    return true;
  } on RangeError {
    return true;
  } catch (e) {
    return false;
  }
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
  'none': isNone,
  'number': isNumber,
  'odd': isOdd,
  'sameas': isSameAs,
  'sequence': isSequence,
  'string': isString,
  'true': isTrue,
  'undefined': isUndefined,
  'upper': isUpper,
};
