library filters;

import 'dart:convert' show LineSplitter;
import 'dart:math' as math;

import 'package:textwrap/textwrap.dart' show TextWrapper;

import 'context.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'markup.dart';
import 'utils.dart';

// TODO(doc): add
final Map<String, Function> filters = <String, Function>{
  'abs': doAbs,
  'attr': passEnvironment(doAttribute),
  'batch': doBatch,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': count,
  'd': doDefault,
  'default': doDefault,
  'dictsort': doDictSort,
  'e': doEscape,
  'escape': doEscape,
  'filesizeformat': doFileSizeFormat,
  'first': doFirst,
  'float': doFloat,
  'forceescape': doForceEscape,
  'int': doInteger,
  'join': passContext(doJoin),
  'last': doLast,
  'length': count,
  'list': list,
  'lower': doLower,
  'map': passContext(doMap),
  'random': passEnvironment(doRandom),
  'replace': doReplace,
  'reverse': doReverse,
  'safe': doMarkSafe,
  'slice': doSlice,
  'string': doString,
  'striptags': doStripTags,
  'sum': passEnvironment(doSum),
  'trim': doTrim,
  'upper': doUpper,
  'wordcount': doWordCount,
  'wordwrap': passEnvironment(doWordWrap),

  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'max': doMax,
  // 'min': doMin,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'round': doRound,
  // 'select': doSelect,
  // 'selectattr': doSelectAttr,
  // 'sort': doSort,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'xmlattr': doXMLAttr,
};

/// Return the absolute value of the argument.
num doAbs(num number) {
  return number.abs();
}

/// Get an attribute of an object.
///
/// `foo|attr('bar')` works like `foo.bar` just that always an attribute
/// is returned and items are not looked up.
Object? doAttribute(Environment environment, Object? object, String attribute) {
  return environment.getAttribute(object, attribute);
}

/// A filter that batches items.
///
/// It works pretty much like slice just the other way round. It returns
/// a list of lists with the given number of items. If you provide
/// a second parameter this is used to fill up missing items.
List<List<Object?>> doBatch(Iterable<Object?> items, int lineCount,
    [Object? fillWith]) {
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

/// Capitalize a value. The first character will be uppercase,
/// all others lowercase.
String doCapitalize(String string) {
  if (string.isEmpty) {
    return '';
  }

  return string[0].toUpperCase() + string.substring(1).toLowerCase();
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

/// If the value is null it will return the passed default value, otherwise the value of the variable.
Object? doDefault(Object? value, [Object? d = '', bool asBoolean = false]) {
  if (value == null || asBoolean && !boolean(value)) {
    return d;
  }

  return value;
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

/// Replace the characters `&`, `<`, `>`, `'`, and `"`
/// in the string with HTML-safe sequences.
///
/// Use this if you need to display text that might contain such characters in HTML.
Object? doEscape(Object? value) {
  return Markup(value);
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
  } else if (bytes < base) {
    const suffix = ' Bytes';
    var size = bytes.toStringAsFixed(1);

    if (size.endsWith('.0')) {
      return size.substring(0, size.length - 2) + suffix;
    }

    return size + suffix;
  } else {
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
}

/// Return the first item of a sequence.
Object? doFirst(Iterable<Object?> values) {
  return values.first;
}

/// Convert the value into a floating point number.
///
/// If the conversion doesn’t work it will return 0.0.
/// You can override this default using the first parameter.
double? doFloat(String value) {
  return double.tryParse(value);
}

/// Enforce HTML escaping.
///
/// This will probably double escape variables.
Markup doForceEscape(Object? value) {
  return Markup(value.toString());
}

/// Convert the value into an integer.
int? doInteger(String value, [int base = 10]) {
  return int.tryParse(value, radix: base) ?? num.tryParse(value)?.toInt();
}

/// Return a string which is the concatenation of the strings in the
/// sequence.
///
/// The separator between elements is an empty string per
/// default, you can define it with the optional parameter
// TODO(difference): join filter
Object? doJoin(Context context, Iterable<Object?> values,
    [String delimiter = '']) {
  if (context.autoEscape) {
    values = values.map<Markup>(Markup.new);
    return Escaped(values.join(delimiter));
  }

  return values.join(delimiter);
}

Object? doLast(Iterable<Object?> values) {
  return values.last;
}

String doLower(String string) {
  return string.toLowerCase();
}

Iterable<Object?> doMap(Context context, Iterable<Object?> values,
    {String? attribute, Object? defaultValue, String? filter}) {
  if (attribute != null) {
    return values.map<Object?>(makeAttributeGetter(
        context.environment, attribute,
        defaultValue: defaultValue));
  }

  if (filter != null) {
    return values
        .map<Object?>((value) => context.filter(filter, <Object?>[value]));
  }

  return values;
}

/// Mark the value as safe which means that in an environment
/// with automatic escaping enabled this variable will not be escaped.
Markup doMarkSafe(String value) {
  return Markup.escaped(value);
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

/// Return a copy of the value with all occurrences of a substring
/// replaced with a new one.
///
/// The first argument is the substring that should be replaced,
/// the second is the replacement string.
/// If the optional third argument [count] is given, only the first
/// `count` occurrences are replaced.
Object? doReplace(Object? object, String from, String to, [int? count]) {
  String string;
  bool isNotMarkup;

  if (object is String) {
    string = object;
    isNotMarkup = true;
  } else if (object is Markup) {
    string = object.toString();
    isNotMarkup = false;
  } else {
    string = object.toString();
    isNotMarkup = true;
  }

  if (count == null) {
    string = string.replaceAll(from, to);
  } else {
    for (var i = 0, s = string.indexOf(from); s != -1 && i < count; i++) {
      string = string.replaceFirst(from, to, s);
    }
  }

  if (isNotMarkup) {
    return string;
  }

  return Markup(string);
}

/// Reverse the object or return an iterator
/// that iterates over it the other way round.
Object? doReverse(Object? value) {
  var values = list(value);
  return values.reversed;
}

/// Slice an iterator and return a list of lists containing
/// those items.
///
/// Useful if you want to create a div containing
/// three ul tags that represent columns.
List<List<Object?>> doSlice(Object? value, int slices, [Object? fillWith]) {
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

/// A string representation of this object.
String doString(Object? value) {
  return value.toString();
}

/// Strip SGML/XML tags and replace adjacent whitespace by one space.
String doStripTags(String value) {
  return stripTags(value);
}

/// Returns the sum of a sequence of numbers plus the value of parameter
/// `start`.
///
/// When the sequence is empty it returns start.
// TODO(difference): sum filter
num doSum(Environment environment, Iterable<Object?> values, [num start = 0]) {
  return values.cast<num>().fold<num>(start, (s, n) => s + n);
}

/// Strip leading and trailing characters, by default whitespace.
String doTrim(String value, [String? characters]) {
  if (characters == null) {
    return value.trim();
  }

  var left = RegExp('^[$characters]+', multiLine: true);
  var right = RegExp('[$characters]+\$', multiLine: true);
  return value.replaceAll(left, '').replaceAll(right, '');
}

/// Convert a value to uppercase.
String doUpper(String value) {
  return value.toUpperCase();
}

/// Count the words in that string.
int doWordCount(String string) {
  var matches = RegExp(r'\w+').allMatches(string);
  return matches.length;
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
      .expand<String>((line) => wrapper.wrap(line))
      .join(wrap);
}

/// Returns a callable that looks up the given attribute from a
/// passed object with the rules of the environment.
///
/// Dots are allowed to access attributes of attributes.
/// Integer parts in paths are looked up as integers.
Object? Function(Object?) makeAttributeGetter(
    Environment environment, String attributeOrAttributes,
    {Object? Function(Object?)? postProcess, Object? defaultValue}) {
  var attributes = attributeOrAttributes.split('.');
  return (Object? item) {
    for (var part in attributes) {
      item = environment.getAttribute(item, part);

      if (item == null) {
        if (defaultValue != null) {
          item = defaultValue;
        }

        break;
      }
    }

    if (postProcess != null) {
      item = postProcess(item);
    }

    return item;
  };
}
