import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

bool eq(Object? value, Object? other) {
  return value == other;
}

bool ge(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) >= 0;
}

bool gt(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) > 0;
}

bool le(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) <= 0;
}

bool lt(Comparable<Object?> value, Comparable<Object?> other) {
  return value.compareTo(other) < 0;
}

bool ne(Object? value, Object? other) {
  return value != other;
}

bool isCallable(Object? value) {
  return value is Function;
}

bool isDefined(Object? value) {
  return toBool(value);
}

bool isDivisibleBy(num value, num divider) {
  if (divider == 0) {
    return false;
  }

  return value % divider == 0;
}

bool isEscaped(Object? value) {
  return value is Markup;
}

bool isEven(num value) {
  return value % 2 == 0;
}

bool isIn(Object? value, Object? values) {
  if (values is String) {
    if (value is Pattern) {
      return values.contains(value);
    }

    throw Exception('$value must be subclass of Pattern');
  }

  if (values is Iterable) {
    return values.contains(value);
  }

  if (values is Map) {
    return values.containsKey(value);
  }

  throw Exception('$values must be one of String, List or Map subclass');
}

bool isIterable(Object? value) {
  return value is Iterable;
}

bool isLower(String value) {
  return value == value.toLowerCase();
}

bool isMapping(Object? value) {
  return value is Map;
}

bool isNone(Object? value) {
  return value == null;
}

bool isNumber(Object? value) {
  return value is num;
}

bool isOdd(num value) {
  return value % 2 == 1;
}

bool isSameAs(Object? value, Object? other) {
  return value == other;
}

bool isSequence(Object? values) {
  if (values is Iterable || values is Map || values is String) {
    return true;
  }

  return false;
}

bool isString(Object? value) {
  return value is String;
}

bool isUndefined(Object? value) {
  return value is Undefined;
}

bool isUpper(String value) {
  return value == value.toUpperCase();
}

final Map<String, Function> tests = <String, Function>{
  'callable': isCallable,
  'defined': isDefined,
  'divisibleby': isDivisibleBy,
  'eq': eq,
  'equalto': eq,
  'escaped': isEscaped,
  'even': isEven,
  'ge': ge,
  'greaterthan': gt,
  'gt': gt,
  'in': isIn,
  'iterable': isIterable,
  'le': le,
  'lessthan': lt,
  'lower': isLower,
  'lt': lt,
  'mapping': isMapping,
  'ne': ne,
  'none': isNone,
  'number': isNumber,
  'odd': isOdd,
  'sameas': isSameAs,
  'sequence': isSequence,
  'string': isString,
  'undefined': isUndefined,
  'upper': isUpper,
};
