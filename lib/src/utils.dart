import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:textwrap/utils.dart';

final RegExp _tagsRe = RegExp('(<!--.*?-->|<[^>]*>)');

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

/// Identity function.
Object? identity(Object? value) {
  return value;
}

/// Return a pair of the `[key, value]` items of a mapping entry.
List<Object?> pair(MapEntry<Object?, Object?> entry) {
  return <Object?>[entry.key, entry.value];
}

/// Convert value to [Iterable]
/// - [Iterable] returns as is
/// - [String] returns chars split by `''`
/// - [Map] returns [Map.keys]
/// - otherwise throws [TypeError].
Iterable<Object?> iterate(Object? value) {
  if (value is Iterable) {
    return value;
  }

  if (value is String) {
    return value.split('');
  }

  if (value is Map) {
    return value.keys;
  }

  if (value is MapEntry) {
    return pair(value);
  }

  throw TypeError();
}

/// Convert value to [List].
///
/// If `value` is `null` returns empty [List] else calls [iterate] and returns
/// [List] as is or wraps returned iterable with [List.of].
List<Object?> list(Object? value) {
  if (value is List) {
    return value;
  }

  return List<Object?>.of(iterate(value));
}

/// Creates an [Iterable] of [int]s that iterates from `start` to `stop` by `step`.
Iterable<int> range(int startOrStop, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    // TODO(error): add message
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

/// HTML escape [Converter].
final HtmlEscape htmlEscape = HtmlEscape(
  HtmlEscapeMode(
    escapeLtGt: true,
    escapeQuot: true,
    escapeApos: true,
  ),
);

/// HTML unescape [Converter].
final HtmlUnescape htmlUnescape = HtmlUnescape();

String escape(String text) {
  return htmlEscape.convert(text);
}

/// Serialize an object to a string of JSON with [JsonEncoder], then replace
/// HTML-unsafe characters with Unicode escapes.
///
/// This is available in templates as the `|tojson` filter.
///
/// The following characters are escaped: `<`, `>`, `&`, `'`.
///
/// {@macro jinja.safestring}
String htmlSafeJsonEncode(Object? value, [String? indent]) {
  var encoder = indent == null ? json.encoder : JsonEncoder.withIndent(indent);

  return encoder
      .convert(value)
      .replaceAll('<', '\\u003c')
      .replaceAll('>', '\\u003e')
      .replaceAll('&', '\\u0026')
      .replaceAll("'", '\\u0027');
}

String unescape(String text) {
  return htmlUnescape.convert(text);
}

/// Capitalize a value.
String capitalize(String value) {
  if (value.isEmpty) {
    return '';
  }

  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

/// Remove tags and normalize whitespace to single spaces.
String stripTags(String value) {
  if (value.isEmpty) {
    return '';
  }

  return unescape(
      RegExp(r'\s+').split(value.replaceAll(_tagsRe, '')).join(' '));
}

/// Sum two values.
// TODO(utils): move to op context
Object? sum(dynamic left, Object? right) {
  // TODO(dynamic): dynamic invocation
  // ignore: avoid_dynamic_calls
  return left + right;
}
