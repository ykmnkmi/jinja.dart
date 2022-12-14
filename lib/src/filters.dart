import 'dart:convert' show LineSplitter;
import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/markup.dart';
import 'package:jinja/src/utils.dart' as utils;
import 'package:textwrap/textwrap.dart' show TextWrapper;

/// Returns a callable that looks up the given attribute from a passed object
/// with the rules of the environment.
Object? Function(Object?) makeAttributeGetter(
  Environment environment,
  String attribute, {
  Object? defaultValue,
}) {
  Object? getter(Object? object) {
    return environment.getAttribute(object, attribute) ?? defaultValue;
  }

  return getter;
}

/// Returns a callable that looks up the given item from a passed object with
/// the rules of the environment.
Object? Function(Object?) makeItemGetter(
  Environment environment,
  Object item, {
  Object? defaultValue,
}) {
  Object? getter(Object? object) {
    return environment.getItem(object, item) ?? defaultValue;
  }

  return getter;
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
Object? doReplace(
  Context context,
  String string,
  String from,
  String to, [
  int? count,
]) {
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
List<Object?> doDictSort(
  Map<Object?, Object?> dict, {
  bool caseSensetive = false,
  String by = 'key',
  bool reverse = false,
}) {
  int position;

  switch (by) {
    case 'key':
      position = 0;
      break;
    case 'value':
      position = 1;
      break;
    default:
      throw FilterArgumentError("You can only sort by either 'key' or 'value'");
  }

  var order = reverse ? -1 : 1;

  List<Object?> map(MapEntry<Object?, Object?> entry) {
    return <Object?>[entry.key, entry.value];
  }

  var entities = dict.entries.map<List<Object?>>(map).toList();

  Comparable<Object?> Function(List<Object?> values) get;

  if (caseSensetive) {
    Comparable<Object?> getter(List<Object?> values) {
      return values[position] as Comparable<Object?>;
    }

    get = getter;
  } else {
    Comparable<Object?> getter(List<Object?> values) {
      var value = values[position];

      if (value is String) {
        return value.toLowerCase();
      }

      return value as Comparable<Object?>;
    }

    get = getter;
  }

  int sort(List<Object?> left, List<Object?> right) {
    return get(left).compareTo(get(right)) * order;
  }

  entities.sort(sort);
  return entities;
}

/// If the value is null it will return the passed default value,
/// otherwise the value of the variable.
Object? doDefault(
  Object? value, [
  Object? defaultValue = '',
  bool asBool = false,
]) {
  if (asBool) {
    return utils.boolean(value) ? value : defaultValue;
  }

  return value ?? defaultValue;
}

/// Return a string which is the concatenation of the strings in the
/// sequence.
///
/// The separator between elements is an empty string per
/// default, you can define it with the optional parameter
Object doJoin(
  Context context,
  Iterable<Object?> values, [
  String delimiter = '',
]) {
  if (context.autoEscape) {
    values = values.map<String>(escapeSafe);
    return Markup.escaped(values.join(escape(delimiter)));
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

  var values = utils.list(value);
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
    <String>[' KiB', ' kB'],
    <String>[' MiB', ' MB'],
    <String>[' GiB', ' GB'],
    <String>[' TiB', ' TB'],
    <String>[' PiB', ' PB'],
    <String>[' EiB', ' EB'],
    <String>[' ZiB', ' ZB'],
    <String>[' YiB', ' YB'],
  ];

  var base = binary ? 1024 : 1000;
  double bytes;

  if (value is num) {
    bytes = value.toDouble();
  } else if (value is String) {
    bytes = double.parse(value);
  } else {
    // or FilterArgumentError?
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

  for (var i = 0; i < suffixes.length; i += 1) {
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
String doTruncate(
  Environment environment,
  String value, {
  int length = 255,
  bool killWords = false,
  String end = '...',
  int leeway = 5,
}) {
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
String doWordWrap(
  Environment environment,
  String string,
  int width, {
  bool breakLongWords = true,
  String? wrapString,
  bool breakOnHyphens = true,
}) {
  var wrapper = TextWrapper(
    width: width,
    expandTabs: false,
    replaceWhitespace: false,
    breakLongWords: breakLongWords,
    breakOnHyphens: breakOnHyphens,
  );

  var wrap = wrapString ?? environment.newLine;
  return const LineSplitter()
      .convert(string)
      .expand<String>(wrapper.wrap)
      .join(wrap);
}

/// Count the words in that string.
int doWordCount(String string) {
  var matches = RegExp(r'\w+').allMatches(string);
  return matches.length;
}

/// Convert the value into an integer.
///
/// If the conversion doesn’t work it will return null.
int doInteger(String value, {int defaultValue = 0, int base = 10}) {
  return int.tryParse(value, radix: base) ?? defaultValue;
}

/// Convert the value into a floating point number.
///
/// If the conversion doesn’t work it will return null.
double doFloat(String value, [double defaultValue = 0.0]) {
  return double.tryParse(value) ?? defaultValue;
}

/// Return the absolute value of the argument.
num doAbs(num number) {
  return number.abs();
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

/// Strip SGML/XML tags and replace adjacent whitespace by one space.
String doStripTags(String value) {
  return utils.stripTags(value);
}

/// Slice an iterator and return a list of lists containing
/// those items.
///
/// Useful if you want to create a div containing
/// three ul tags that represent columns.
List<List<Object?>> doSlice(Object? value, int slices, [Object? fillWith]) {
  var result = <List<Object?>>[];
  var values = utils.list(value);
  var length = values.length;
  var perSlice = length ~/ slices;
  var withExtra = length % slices;

  for (var i = 0, offset = 0; i < slices; i += 1) {
    var start = offset + i * perSlice;

    if (i < withExtra) {
      offset += 1;
    }

    var end = offset + (i + 1) * perSlice;

    Object? generator(int i) {
      return values[start + i];
    }

    var tmp = List<Object?>.generate(end - start, generator);

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
List<List<Object?>> doBatch(
  Iterable<Object?> items,
  int lineCount, [
  Object? fillWith,
]) {
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
      temp += List<Object?>.filled(lineCount - temp.length, fillWith);
    }

    result.add(temp);
  }

  return result;
}

/// Return the number of items in a container.
int? doLength(dynamic object) {
  try {
    // TODO: dynamic invocation
    // ignore: avoid_dynamic_calls
    return object.length as int;
  } on NoSuchMethodError {
    return null;
  }
}

/// Returns the sum of a sequence of numbers plus the value of parameter
/// `start`.
///
/// When the sequence is empty it returns start.
num doSum(Iterable<Object?> values, [num start = 0]) {
  return values.cast<num>().fold<num>(start, (s, n) => s + n);
}

/// Convert the value into a list.
///
/// If it was a string the returned list will be a list of characters.
List<Object?> doList(Object? object) {
  return utils.list(object);
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
  var values = utils.list(value);
  return values.reversed;
}

/// Applies a filter on a sequence of objects or looks up an attribute.
/// This is useful when dealing with lists of objects but you are really
/// only interested in a certain value of it.
///
/// The basic usage is mapping on an attribute or item.
Iterable<Object?>? doMap(
  Context context,
  Iterable<Object?>? values, {
  String? filter,
  String? attribute,
  Object? item,
  Object? defaultValue,
  List<Object?> positional = const <Object?>[],
  Map<Object?, Object?> named = const <Object?, Object?>{},
}) {
  if (values == null) {
    return null;
  }

  Object? Function(Object?)? getter;

  if (attribute != null) {
    getter = makeAttributeGetter(
      context.environment,
      attribute,
      defaultValue: defaultValue,
    );
  } else if (item != null) {
    getter = makeItemGetter(
      context.environment,
      item,
      defaultValue: defaultValue,
    );
  }

  if (getter != null) {
    if (named.isNotEmpty) {
      var name = named.keys.first;
      throw FilterArgumentError('Unexpected keyword argument $name');
    }

    return values.map<Object?>(getter);
  }

  if (filter == null) {
    throw FilterArgumentError('Map requires a filter argument');
  }

  var symbols = <Symbol, Object?>{};

  void action(String key, Object? value) {
    symbols[Symbol(key)] = value;
  }

  named.cast<String, Object?>().forEach(action);

  Object? map(Object? value) {
    return context.filter(filter, <Object?>[value, ...positional], symbols);
  }

  return values.map<Object?>(map);
}

/// Get an attribute of an object.
///
/// `foo | attr('bar')` works like `foo.bar`.
Object? doAttribute(Environment environment, Object? value, String attribute) {
  return environment.getAttribute(value, attribute);
}

/// Get an item of an object.
///
/// `foo | item('bar')` works like `foo['bar']`.
Object? doItem(Environment environment, Object? value, Object? item) {
  return environment.getItem(value, item);
}

/// Serialize an object to a string of JSON, and mark it safe to render in
/// HTML.
///
/// This filter is only for use in HTML documents.
///
/// {@template safestring}
/// The returned string is safe to render in HTML documents and `<script>` tags.
/// The exception is in HTML attributes that are double quoted; either use
/// single quotes or the `|forceescape` filter.
/// {@endtemplate}
Markup doToJson(Object? value, [String? indent]) {
  return utils.htmlSafeJsonEncode(value, indent);
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
  'count': doLength,
  'length': doLength,
  'sum': doSum,
  'list': doList,
  'safe': doMarkSafe,
  'unsafe': doMarkUnsafe,
  'reverse': doReverse,
  'attr': passEnvironment(doAttribute),
  'item': passEnvironment(doItem),
  'map': passContext(doMap),
  // 'select': passContext(doSelect),
  // 'reject': passContext(doReject),
  // 'selectattr': passContext(doSelectAttr),
  // 'rejectattr': passContext(doRejectAttr),
  'tojson': doToJson,
};
