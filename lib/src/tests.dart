import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

eq(value, other) => value == other;
ge(value, other) => value >= other;
gt(value, other) => value > other;
le(value, other) => value <= other;
lt(value, other) => value < other;
ne(value, other) => value != other;

/// Return `true` if the variable is odd.
bool doOdd(num value) => value % 2 == 1;

/// Return `true` if the variable is even.
bool doEven(num value) => value % 2 == 0;

/// Check if a variable is divisible by a number.
bool doDivisibleBy(num value, num divider) {
  if (divider == 0) return false;
  return value % divider == 0;
}

/// Return `true` if the variable is defined.
///
/// See the `default` filter for a simple way to set undefined
/// variables.
bool doDefined(value) => asBool(value);

/// Like `defined` but the other way round.
bool doUndefined(value) => !asBool(value);

/// Return `true` if the variable is [Undefined].
bool doNone(value) => value is Undefined;

/// Return `true` if the variable is lowercased.
bool doLower(String value) => value == value.toLowerCase();

/// Return `true` if the variable is uppercased.
bool doUpper(String value) => value == value.toUpperCase();

/// Return `true` if the object is a [String].
bool doString(value) => value is String;

/// Return `true` if the object is a mapping ([Map] etc.).
bool doMapping(value) => value is Map;

/// Return `true` if the variable is a [num].
bool doNumber(value) => value is num;

/// Return `true` if the variable is a sequence. Sequences are variables
/// that are [Iterable].
bool doSequence(seq) {
  if (seq is Iterable || seq is Map || seq is String) return true;
  return false;
}

/// Check if an object points to the same memory address than another
/// object.
bool doSameAs(value, other) => value == other;

/// Check if it's possible to iterate over an object.
bool doIterable(value) => value is Iterable;

/// Check if the value is escaped.
bool doEscaped(value) => value is Markup;

/// Check if value is in seq.
bool doIn(value, seq) {
  if (seq is Iterable) return seq.contains(value);
  if (seq is Map) return seq.containsKey(value);
  if (seq is String) return seq.contains(value as Pattern);
  return false;
}

/// Return `true` if the variable is [Function].
bool doCallable(value) => value is Function;

const tests = {
  'eq': eq,
  'equalto': eq,
  'ge': ge,
  'greaterthan': gt,
  'gt': gt,
  'in': doIn,
  'le': le,
  'lessthan': lt,
  'lt': lt,
  'ne': ne,
  'even': doEven,
  'odd': doOdd,
  'divisibleby': doDivisibleBy,
  'defined': doDefined,
  'undefined': doUndefined,
  'none': doNone,
  'lower': doLower,
  'upper': doUpper,
  'string': doString,
  'mapping': doMapping,
  'number': doNumber,
  'sequence': doSequence,
  'sameas': doSameAs,
  'iterable': doIterable,
  'escaped': doEscaped,
  'callable': doCallable,
};
