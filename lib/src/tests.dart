import 'markup.dart';
import 'utils.dart';

const Map<String, Function> tests = <String, Function>{
  'callable': istCallable,
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

bool eq(dynamic value, dynamic other) => value == other;
bool ge(dynamic value, dynamic other) => (value >= other) as bool;
bool gt(dynamic value, dynamic other) => (value > other) as bool;
bool le(dynamic value, dynamic other) => (value <= other) as bool;
bool lt(dynamic value, dynamic other) => (value < other) as bool;
bool ne(dynamic value, dynamic other) => value != other;

bool istCallable(dynamic value) => value is Function;

bool isDefined(dynamic value) => toBool(value);

bool isDivisibleBy(num value, num divider) {
  if (divider == 0) return false;
  return value % divider == 0;
}

bool isEscaped(dynamic value) => value is Markup;

bool isEven(num value) => value % 2 == 0;

bool isIn(dynamic value, dynamic values) {
  try {
    if (values is Iterable) return values.contains(value);
    if (values is Map) return values.containsKey(value);
    if (values is String) return values.contains(value as Pattern);
  } catch (_) {}

  return false;
}

bool isIterable(dynamic value) => value is Iterable;

bool isLower(String value) => value == value.toLowerCase();

bool isMapping(value) => value is Map;

bool isNone(dynamic value) => value == null;

bool isNumber(dynamic value) => value is num;

bool isOdd(num value) => value % 2 == 1;

bool isSameAs(dynamic value, dynamic other) => value == other;

bool isSequence(dynamic values) {
  if (values is Iterable || values is Map || values is String) return true;
  return false;
}

bool isString(dynamic value) => value is String;

bool isUndefined(dynamic value) => !toBool(value);

bool isUpper(String value) => value == value.toUpperCase();
