import 'package:textwrap/utils.dart';

Object? identity(Object? object) {
  return object;
}

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

  if (value is Iterable) {
    return value.isNotEmpty;
  }

  if (value is Map) {
    return value.isNotEmpty;
  }

  return true;
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

  if (iterable is MapEntry) {
    return <Object?>[iterable.key, iterable.value];
  }

  if (iterable is Map) {
    return iterable.entries.toList();
  }

  throw TypeError();
}

Iterable<Object?> iterate(Object? iterable) {
  if (iterable is Iterable) {
    return iterable;
  }

  if (iterable is String) {
    return iterable.split('');
  }

  if (iterable is MapEntry) {
    return [iterable.key, iterable.value];
  }

  if (iterable is Map) {
    return iterable.entries;
  }

  throw TypeError();
}

Iterable<int> range(int startOrStop, [int? stop, int step = 1]) sync* {
  if (step == 0) {
    throw ArgumentError.value(step, 'step', 'must not be zero');
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

List<R> generate<T, R>(
  List<T> list,
  R Function(int) generator, {
  bool growable = true,
}) {
  return List<R>.generate(list.length, generator, growable: growable);
}

String repr(Object? object, [bool escapeNewlines = false]) {
  var buffer = StringBuffer();
  reprTo(object, buffer, escapeNewlines);
  return buffer.toString();
}

void reprTo(
  Object? object,
  StringBuffer buffer, [
  bool escapeNewlines = false,
]) {
  if (object is String) {
    object = object.replaceAll("'", "\\'");

    if (escapeNewlines) {
      String replace(Match match) {
        return match.group(1) ?? '';
      }

      object = object.replaceAllMapped(RegExp('(\r\n|\r|\n)'), replace);
    }

    buffer.write("'$object'");
    return;
  }

  if (object is List) {
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

  if (object is Map) {
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
