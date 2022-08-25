library filters;

import 'dart:convert' show LineSplitter;
import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart';
import 'package:textwrap/textwrap.dart' show TextWrapper;

/// Returns a callable that looks up the given attribute from a
/// passed object with the rules of the environment.
///
/// Dots are allowed to access attributes of attributes.
/// Integer parts in paths are looked up as integers.
Object? Function(Object?) makeAttributeGetter(
    Environment environment, Object? attribute,
    {Object? Function(Object?)? postProcess, Object? defaultValue}) {
  Object? Function(Object? object) getter;

  if (attribute == null) {
    getter = identity;
  } else if (attribute is String) {
    var parts = attribute.split('.');

    getter = (Object? object) {
      for (var part in parts) {
        object = environment.getAttribute(object, part);

        if (object == null) {
          if (defaultValue != null) {
            object = defaultValue;
          }

          break;
        }
      }
    };
  } else {
    getter = (Object? object) {
      return environment.getItem(object, attribute);
    };
  }

  return (Object? item) {
    item = getter(item);

    if (postProcess != null) {
      item = postProcess(item);
    }

    return item;
  };
}

/// Replace the characters `&`, `<`, `>`, `'`, and `"`
/// in the string with HTML-safe sequences.
///
/// Use this if you need to display text that might contain such characters in HTML.
Object? doEscape(Object? value) {
  return Markup(value);
}

/// Enforce HTML escaping.
///
/// This will probably double escape variables.
Markup doForceEscape(Object? value) {
  return Markup(value.toString());
}

/// A string representation of this object.
String doString(Object? value) {
  return value.toString();
}

/// Return a copy of the value with all occurrences of a substring
/// replaced with a new one.
///
/// The first argument is the substring that should be replaced,
/// the second is the replacement string.
/// If the optional third argument [count] is given, only the first
/// `count` occurrences are replaced.
Object? doReplace(Context context, String string, String from, String to,
    {int? count}) {
  if (count == null) {
    string = string.replaceAll(from, to);
  } else {
    var start = string.indexOf(from);
    var n = 0;

    while (n < count && start != -1 && start < string.length) {
      var start = string.indexOf(from);
      string = string.replaceRange(start, start + from.length, to);
      start = string.indexOf(from, start + to.length);
      n += 1;
    }
  }

  if (context.autoEscape) {
    return context.escape(string);
  }

  return string;
}

/// Convert a value to uppercase.
String doUpper(String value) {
  return value.toUpperCase();
}

/// Convert a value to lowercase.
String doLower(String string) {
  return string.toLowerCase();
}

/// Capitalize a value. The first character will be uppercase,
/// all others lowercase.
String doCapitalize(String string) {
  if (string.isEmpty) {
    return '';
  }

  return string[0].toUpperCase() + string.substring(1).toLowerCase();
}

/// Sort a dict and yield `[key, value]` pairs.
List<Object?> doDictSort(Map<Object?, Object?> dict,
    {bool caseSensetive = false, String by = 'key', bool reverse = false}) {
  int pos;

  switch (by) {
    case 'key':
      pos = 0;
      break;

    case 'value':
      pos = 1;
      break;

    default:
      throw FilterArgumentError("you can only sort by either 'key' or 'value'");
  }

  var order = reverse ? -1 : 1;
  var entities = dict.entries
      .map<List<Object?>>((entry) => <Object?>[entry.key, entry.value])
      .toList();

  Comparable<Object?> Function(List<Object?> values) getter;

  if (caseSensetive) {
    getter = (List<Object?> values) {
      return values[pos] as Comparable<Object?>;
    };
  } else {
    getter = (List<Object?> values) {
      var value = values[pos];

      if (value is String) {
        return value.toLowerCase();
      }

      return value as Comparable<Object?>;
    };
  }

  entities.sort((a, b) => getter(a).compareTo(getter(b)) * order);
  return entities;
}

/// If the value is null it will return the passed default value,
/// otherwise the value of the variable.
Object? doDefault(Object? value,
    [Object? defaultValue = '', bool asBoolean = false]) {
  if (value == null || asBoolean && !boolean(value)) {
    return defaultValue;
  }

  return value;
}

/// Return a string which is the concatenation of the strings in the
/// sequence.
///
/// The separator between elements is an empty string per
/// default, you can define it with the optional parameter
Object? doJoin(Context context, Iterable<Object?> values,
    [String delimiter = '']) {
  if (context.autoEscape) {
    values = values.map<Object?>(context.escape);
    return Markup.escaped(values.join(delimiter));
  }

  return values.join(delimiter);
}

/// Centers the value in a field of a given width.
String doCenter(String string, int width) {
  if (string.length >= width) {
    return string;
  }

  var padLength = (width - string.length) ~/ 2;
  var pad = ' ' * padLength;
  return pad + string + pad;
}

/// Return the first item of a sequence.
Object? doFirst(Iterable<Object?> values) {
  return values.first;
}

/// Return the last item of a sequence.
Object? doLast(Iterable<Object?> values) {
  return values.last;
}

/// Return a random item from the sequence.
Object? doRandom(Environment environment, Object? value) {
  if (value == null) {
    return null;
  }

  var values = list(value);
  var index = environment.random.nextInt(values.length);
  var result = values[index];

  if (value is Map) {
    return value[result];
  }

  return result;
}

/// Format the value like a 'human-readable' file size (i.e. 13 kB, 4.1 MB, 102 Bytes, etc).
///
/// Per default decimal prefixes are used (Mega, Giga, etc.), if the second
/// parameter is set to True the binary prefixes are used (Mebi, Gibi).
String doFileSizeFormat(Object? value, [bool binary = false]) {
  const suffixes = <List<String>>[
    [' KiB', ' kB'],
    [' MiB', ' MB'],
    [' GiB', ' GB'],
    [' TiB', ' TB'],
    [' PiB', ' PB'],
    [' EiB', ' EB'],
    [' ZiB', ' ZB'],
    [' YiB', ' YB'],
  ];

  var base = binary ? 1024 : 1000;
  double bytes;

  if (value is num) {
    bytes = value.toDouble();
  } else if (value is String) {
    bytes = double.parse(value);
  } else {
    throw TypeError();
  }

  if (bytes == 1.0) {
    return '1 Byte';
  }

  if (bytes < base) {
    const suffix = ' Bytes';
    var size = bytes.toStringAsFixed(1);

    if (size.endsWith('.0')) {
      return size.substring(0, size.length - 2) + suffix;
    }

    return size + suffix;
  }

  var k = binary ? 0 : 1;
  num unit = 0.0;

  for (var i = 0; i < 8; i += 1) {
    unit = math.pow(base, i + 2);

    if (bytes < unit) {
      return (base * bytes / unit).toStringAsFixed(1) + suffixes[i][k];
    }
  }

  return (base * bytes / unit).toStringAsFixed(1) + suffixes.last[k];
}

/// Return a truncated copy of the string.
///
/// The length is specified with the first parameter which defaults to `255`.
/// If the second parameter is `true` the filter will cut the text at length.
/// Otherwise it will discard the last word. If the text was in fact truncated
/// it will append an ellipsis sign (`"..."`). If you want a different ellipsis
/// sign than `"..."` you can specify it using the third parameter. Strings
/// that only exceed the length by the tolerance margin given in the fourth
/// parameter will not be truncated.
String doTruncate(Environment environment, String value,
    {int length = 255,
    bool killWords = false,
    String end = '...',
    int leeway = 5}) {
  assert(length >= end.length, 'expected length >= ${end.length}, got $length');
  assert(leeway >= 0, 'expected leeway >= 0, got $leeway');

  if (value.length <= length + leeway) {
    return value;
  }

  var substring = value.substring(0, length - end.length);

  if (killWords) {
    return substring + end;
  }

  var found = substring.lastIndexOf(' ');

  if (found == -1) {
    return substring + end;
  }

  return substring.substring(0, found) + end;
}

/// Wrap a string to the given width.
///
/// Existing newlines are treated as paragraphs to be wrapped separately.
String doWordWrap(Environment environment, String string, int width,
    {bool breakLongWords = true,
    String? wrapString,
    bool breakOnHyphens = true}) {
  var wrapper = TextWrapper(
      width: width,
      expandTabs: false,
      replaceWhitespace: false,
      breakLongWords: breakLongWords,
      breakOnHyphens: breakOnHyphens);
  var wrap = wrapString ?? environment.newLine;
  return const LineSplitter()
      .convert(string)
      .expand<String>(wrapper.wrap)
      .join(wrap);
}

/// Count the words in that string.
int doWordCount(String string) {
  var matches = RegExp('\\w+').allMatches(string);
  return matches.length;
}

/// Convert the value into an integer.
///
/// If the conversion doesn’t work it will return null.
int? doInteger(String value, {int radix = 10, int? defaultValue}) {
  return int.tryParse(value, radix: radix) ?? defaultValue;
}

/// Convert the value into a floating point number.
///
/// If the conversion doesn’t work it will return null.
double? doFloat(String value, {double? defaultValue}) {
  return double.tryParse(value) ?? defaultValue;
}

/// Return the absolute value of the argument.
num doAbs(num number) {
  return number.abs();
}

/// Strip leading and trailing characters, by default whitespace.
String doTrim(String value, {String? characters}) {
  if (characters == null) {
    return value.trim();
  }

  var left = RegExp('^[$characters]+', multiLine: true);
  var right = RegExp('[$characters]+\$', multiLine: true);
  return value.replaceAll(left, '').replaceAll(right, '');
}

/// Strip SGML/XML tags and replace adjacent whitespace by one space.
String doStripTags(String value) {
  return stripTags(value);
}

/// Slice an iterator and return a list of lists containing
/// those items.
///
/// Useful if you want to create a div containing
/// three ul tags that represent columns.
List<List<Object?>> doSlice(Object? value, int slices, {Object? fillWith}) {
  var result = <List<Object?>>[];
  var values = list(value);
  var length = values.length;
  var perSlice = length ~/ slices;
  var withExtra = length % slices;

  for (var i = 0, offset = 0; i < slices; i += 1) {
    var start = offset + i * perSlice;

    if (i < withExtra) {
      offset += 1;
    }

    var end = offset + (i + 1) * perSlice;
    var tmp = List<Object?>.generate(end - start, (i) => values[start + i]);

    if (fillWith != null && i >= withExtra) {
      tmp.add(fillWith);
    }

    result.add(tmp);
  }

  return result;
}

/// A filter that batches items.
///
/// It works pretty much like slice just the other way round. It returns
/// a list of lists with the given number of items. If you provide
/// a second parameter this is used to fill up missing items.
List<List<Object?>> doBatch(Iterable<Object?> items, int lineCount,
    {Object? fillWith}) {
  var result = <List<Object?>>[];
  var temp = <Object?>[];

  for (var item in items) {
    if (temp.length == lineCount) {
      result.add(temp);
      temp = <Object?>[];
    }

    temp.add(item);
  }

  if (temp.isNotEmpty) {
    if (fillWith != null) {
      for (var i = 0; i <= lineCount - temp.length; i += 1) {
        temp.add(fillWith);
      }
    }

    result.add(temp);
  }

  return result;
}

/// Return the number of items in a container.
int? doLength(Environment environment, dynamic object) {
  try {
    // * dynamic invocation
    return object.length as int;
  } on NoSuchMethodError {
    return null;
  }
}

/// Returns the sum of a sequence of numbers plus the value of parameter
/// `start`.
///
/// When the sequence is empty it returns start.
num doSum(Iterable<num> values, {num start = 0}) {
  return values.fold<num>(start, (s, n) => s + n);
}

/// Convert the value into a list.
///
/// If it was a string the returned list will be a list of characters.
List<Object?> doList(Object? object) {
  return list(object);
}

/// Mark the value as safe which means that in an environment
/// with automatic escaping enabled this variable will not be escaped.
Markup doMarkSafe(String value) {
  return Markup.escaped(value);
}

/// Mark a value as unsafe.
///
/// This is the reverse operation for `safe`.
String doMarkUnsafe(Object? value) {
  return value.toString();
}

/// Reverse the object or return an iterator that iterates over it the other
/// way round.
Object? doReverse(Object? value) {
  var values = list(value);
  return values.reversed;
}

/// Get an attribute of an object.
///
/// `foo | attr('bar')` works like `foo.bar`.
Object? doAttribute(Environment environment, Object? object, String attribute) {
  return environment.getAttribute(object, attribute);
}

/// Get an item of an object.
///
/// `foo | item('bar')` works like `foo['bar']`.
Object? doItem(Environment environment, Object? object, Object? item) {
  return environment.getItem(object, item);
}

final Map<String, Function> filters = <String, Function>{
  'e': doEscape,
  'escape': doEscape,
  'forceescape': doForceEscape,
  'string': doString,
  // 'urlencode': doURLEncode,
  'replace': passContext(doReplace),
  'upper': doUpper,
  'lower': doLower,
  // 'xmlattr': passContext(doXMLAttr),
  'capitalize': doCapitalize,
  // 'title': doTitle,
  'dictsort': doDictSort,
  // 'sort': passEnvironment(doSort),
  // 'unique': passEnvironment(doUnique),
  // 'min': passEnvironment(doMin),
  // 'max': passEnvironment(doMax),
  'd': doDefault,
  'default': doDefault,
  'join': passContext(doJoin),
  'center': doCenter,
  'first': doFirst,
  'last': doLast,
  'random': passEnvironment(doRandom),
  'filesizeformat': doFileSizeFormat,
  // 'pprint': doPPrint,
  // 'urlize': passContext(doUrlize),
  // 'indent': doIndent,
  'truncate': passEnvironment(doTruncate),
  'wordwrap': passEnvironment(doWordWrap),
  'wordcount': doWordCount,
  'int': doInteger,
  'float': doFloat,
  'abs': doAbs,
  // 'format': doFormat,
  'trim': doTrim,
  'striptags': doStripTags,
  'slice': doSlice,
  'batch': doBatch,
  // 'round': doRound,
  // 'groupby': passEnvironment(doGroupBy),
  'count': passEnvironment(doLength),
  'length': passEnvironment(doLength),
  'sum': doSum,
  'list': doList,
  'safe': doMarkSafe,
  'unsafe': doMarkUnsafe,
  'reverse': doReverse,
  'attr': passEnvironment(doAttribute),
  'item': passEnvironment(doItem),
  // 'select': passContext(doSelect),
  // 'reject': passContext(doReject),
  // 'selectattr': passContext(doSelectAttr),
  // 'rejectattr': passContext(doRejectAttr),
  // 'tojson': passContext(doToJson),
};
