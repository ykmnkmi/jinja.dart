import 'package:textwrap/utils.dart';

bool boolean(Object? value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0.0;
  }

  if (value is String) {
    return value.isNotEmpty;
  }

  if (value is Iterable<Object?>) {
    return value.isNotEmpty;
  }

  if (value is Map<Object?, Object?>) {
    return value.isNotEmpty;
  }

  return true;
}

int count(dynamic iterable) {
  // if (iterable is Iterable) {
  //   return iterable.length;
  // }

  // if (iterable is String) {
  //   return iterable.length;
  // }

  // if (iterable is Map) {
  //   return iterable.length;
  // }

  // throw TypeError();
  return iterable.length as int;
}

String escape(String text) {
  var start = 0;
  StringBuffer? result;

  for (var i = 0; i < text.length; i++) {
    String? replacement;

    switch (text[i]) {
      case '&':
        replacement = '&amp;';
        break;
      case '"':
        replacement = '&#34;';
        break;
      case "'":
        replacement = '&#39;';
        break;
      case '<':
        replacement = '&lt;';
        break;
      case '>':
        replacement = '&gt;';
        break;
    }

    if (replacement != null) {
      result ??= StringBuffer();
      result.write(text.substring(start, i));
      result.write(replacement);
      start = i + 1;
    }
  }

  if (result == null) {
    return text;
  } else {
    result.write(text.substring(start));
  }

  return result.toString();
}

String format(Object? object) {
  return repr(object);
}

List<Object?> list(Object? iterable) {
  if (iterable is List) {
    return iterable;
  }

  if (iterable is Iterable) {
    return iterable.toList();
  }

  if (iterable is String) {
    return iterable.split('');
  }

  if (iterable is Map) {
    return iterable.keys.toList();
  }

  throw TypeError();
}

Iterable<int> range(int stopOrStart, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    throw StateError('range() argument 3 must not be zero');
  }

  int start;

  if (stop == null) {
    start = 0;
    stop = stopOrStart;
  } else {
    start = stopOrStart;
    stop = stop;
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

String repr(Object? object, [bool escapeNewlines = false]) {
  var buffer = StringBuffer();
  reprTo(object, buffer, escapeNewlines);
  return buffer.toString();
}

void reprTo(Object? object, StringBuffer buffer,
    [bool escapeNewlines = false]) {
  if (object is String) {
    object = object.replaceAll("'", "\\'");

    if (escapeNewlines) {
      object = object.replaceAllMapped(RegExp('(\r\n|\r|\n)'), (match) {
        return match.group(1) ?? '';
      });
    }

    buffer.write("'$object'");
    return;
  }

  if (object is List<Object?>) {
    buffer.write('[');

    for (var i = 0; i < object.length; i += 1) {
      if (i > 0) {
        buffer.write(', ');
      }

      reprTo(object[i], buffer);
    }

    buffer.write(']');
    return;
  }

  if (object is Map<Object?, Object?>) {
    var keys = object.keys.toList();
    buffer.write('{');

    for (var i = 0; i < keys.length; i += 1) {
      if (i > 0) {
        buffer.write(', ');
      }

      reprTo(keys[i], buffer);
      buffer.write(': ');
      reprTo(object[keys[i]], buffer);
    }

    buffer.write('}');
    return;
  }

  buffer.write(object);
}

String stripTags(String value) {
  if (value.isEmpty) {
    return '';
  }

  return RegExp('\\s+')
      .split(value.replaceAll(RegExp('(<!--.*?-->|<[^>]*>)'), ''))
      .join(' ');
}
