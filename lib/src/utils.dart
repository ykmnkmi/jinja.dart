import 'package:jinja/src/markup.dart';
import 'package:textwrap/utils.dart';

/// Jinja [Environment] function types.
///
/// See [passContext] and [passEnvironment].
enum PassArgument {
  /// Function with [Context] argument.
  ///
  /// See [passContext].
  context,

  /// Function with [Environment] argument.
  ///
  /// See [passEnvironment].
  environment;

  /// Type cache for functions, filters and tests.
  static final Expando<PassArgument> types = Expando<PassArgument>();
}

/// Convert value to [bool]
/// - [bool] returns as is
/// - [num] returns `true` if `value` is not equal to `0.0`
/// - [String] returns `true` if `value` is not empty
/// - [Iterable] returns `true` if `value` is not empty
/// - [Map] returns `true` if `value` is not empty
/// - otherwise returns `true` if `value` is not `null`.
bool boolean(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0.0;
  }

  if (value is String) {
    return value.isNotEmpty;
  }

  if (value is Iterable) {
    return value.isNotEmpty;
  }

  if (value is Map) {
    return value.isNotEmpty;
  }

  return value != null;
}

/// Shorthand for [List.generate].
List<R> generate<T, R>(
  List<T> list,
  R Function(int) generator,
) {
  return List<R>.generate(list.length, generator);
}

/// Identity function.
Object? identity(Object? value) {
  return value;
}

/// Convert value to [Iterable]
/// - [Iterable] returns as is
/// - [String] returns chars split by `''`
/// - [MapEntry] returns `[key, value]` list
/// - [Map] returns [Map.entries]
/// - otherwise throws [TypeError].
Iterable<Object?> iterate(Object? value) {
  if (value is Iterable) {
    return value;
  }

  if (value is String) {
    return value.split('');
  }

  if (value is MapEntry) {
    return <Object?>[value.key, value.value];
  }

  if (value is Map) {
    return value.entries;
  }

  // TODO: update error
  throw TypeError();
}

/// Convert value to [List].
///
/// If `value` is `null` returns empty [List] else calls [iterate] and returns
/// [List] as is or wraps returned iterable with [List.of].
List<Object?> list(Object? value) {
  if (value == null) {
    return <Object?>[];
  }

  if (value is List) {
    return value;
  }

  return List<Object?>.of(iterate(value));
}

/// Creates an [Iterable] of [int]s that iterates from `start` to `stop` by `step`.
Iterable<int> range(int startOrStop, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    // TODO: update error
    throw ArgumentError.value(step, 'step');
  }

  int start;

  if (stop == null) {
    start = 0;
    stop = startOrStop;
  } else {
    start = startOrStop;
  }

  if (step < 0) {
    for (var i = start; i >= stop; i += step) {
      yield i;
    }
  } else {
    for (var i = start; i < stop; i += step) {
      yield i;
    }
  }
}

/// Remove tags and normalize whitespace to single spaces.
String stripTags(String value) {
  if (value.isEmpty) {
    return '';
  }

  return unescape(RegExp(r'\s+')
      .split(value.replaceAll(RegExp('(<!--.*?-->|<[^>]*>)'), ''))
      .join(' '));
}
