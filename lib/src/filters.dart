library filters;

import 'dart:convert';
import 'dart:math' as math;

import 'package:textwrap/textwrap.dart';

import 'environment.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

Object? Function(Object?) makeAttributeGetter(
    Environment environment, String attributeOrAttributes,
    {Object? Function(Object?)? postProcess, Object? defaultValue}) {
  final attributes = attributeOrAttributes.split('.');

  Object? attributeGetter(Object? item) {
    for (final part in attributes) {
      item = doAttribute(environment, item, part);

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
  }

  return attributeGetter;
}

num doAbs(num number) {
  return number.abs();
}

Object? doAttribute(Environment environment, Object? object, String attribute) {
  return environment.getAttribute(object, attribute);
}

List<List<Object?>> doBatch(Iterable<Object?> items, int lineCount,
    [Object? fillWith]) {
  final result = <List<Object?>>[];
  var temp = <Object?>[];

  for (final item in items) {
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

String doCapitalize(String string) {
  if (string.length == 1) {
    return string.toUpperCase();
  }

  return string.substring(0, 1).toUpperCase() +
      string.substring(1).toLowerCase();
}

String doCenter(String string, int width) {
  if (string.length >= width) {
    return string;
  }

  final padLength = (width - string.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + string + pad;
}

Object? doDefault(Object? value, [Object? d = '', bool asBoolean = false]) {
  if (value == null || asBoolean && !boolean(value)) {
    return d;
  }

  return value;
}

List<Object?> doDictSort(Map<Comparable<Object?>, Object?> dict) {
  throw UnimplementedError();
}

Markup doEscape(Object? value) {
  if (value is Markup) {
    return value;
  }

  return Markup(value as String);
}

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

  final base = binary ? 1024 : 1000;

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
    final size = bytes.toStringAsFixed(1);

    if (size.endsWith('.0')) {
      return size.substring(0, size.length - 2) + suffix;
    }

    return size + suffix;
  } else {
    final k = binary ? 0 : 1;
    num unit = 0;

    for (var i = 0; i < 8; i += 1) {
      unit = math.pow(base, i + 2);

      if (bytes < unit) {
        return (base * bytes / unit).toStringAsFixed(1) + suffixes[i][k];
      }
    }

    return (base * bytes / unit).toStringAsFixed(1) + suffixes.last[k];
  }
}

Object? doFirst(Iterable<Object?> values) {
  return values.first;
}

double doFloat(String value, {double defaultValue = 0.0}) {
  try {
    return double.tryParse(value) ?? defaultValue;
  } on FormatException {
    return defaultValue;
  }
}

Markup doForceEscape(Object? value) {
  return Markup('$value');
}

int doInteger(String value, {int defaultValue = 0, int base = 10}) {
  if (base == 16 && value.startsWith('0x')) {
    value = value.substring(2);
  }

  try {
    return int.parse(value, radix: base);
  } on FormatException {
    if (base == 10) {
      try {
        return double.parse(value).toInt();
      } on FormatException {
        return defaultValue;
      }
    }

    return defaultValue;
  }
}

Object? doJoin(Context context, Iterable<Object?> values,
    [String delimiter = '', String? attribute]) {
  if (attribute != null) {
    values = values
        .map<Object?>(makeAttributeGetter(context.environment, attribute));
  }

  if (context.autoEscape) {
    return Escaped(
        values.map<Object?>((value) => Markup.escape(value)).join(delimiter));
  }

  return values.join(delimiter);
}

Object? doLast(Iterable<Object?> values) {
  return values.last;
}

String doLower(String string) {
  return string.toLowerCase();
}

String doPPrint(Object? object) {
  return format(object);
}

Object? doRandom(Environment environment, Object? value) {
  if (value == null) {
    return null;
  }

  final values = list(value);
  final index = environment.random.nextInt(values.length);
  final result = values[index];
  return value is Map ? value[result] : result;
}

Object? doReplace(Object? object, String from, String to, [int? count]) {
  String string;
  bool isNotMarkup;

  if (object is String) {
    string = object;
    isNotMarkup = true;
  } else if (object is Markup) {
    string = '$object';
    isNotMarkup = false;
  } else {
    string = '$object';
    isNotMarkup = true;
  }

  if (count == null) {
    string = string.replaceAll(from, to);
  } else {
    for (var i = 0, s = string.indexOf(from); s != -1 && i < count; i++) {
      string = string.replaceFirst(from, to, s);
    }
  }

  return isNotMarkup ? string : Markup(string);
}

Object? doReverse(Object? value) {
  final values = list(value);
  return values.reversed;
}

Markup doMarkSafe(String value) {
  return Markup.escaped(value);
}

List<List<Object?>> doSlice(Object? value, int slices, [Object? fillWith]) {
  final result = <List<Object?>>[];
  final values = list(value);
  final length = values.length;
  final perSlice = length ~/ slices;
  final withExtra = length % slices;

  for (var i = 0, offset = 0; i < slices; i += 1) {
    final start = offset + i * perSlice;

    if (i < withExtra) {
      offset += 1;
    }

    final end = offset + (i + 1) * perSlice;
    // sublist
    final tmp =
        List<Object?>.generate(end - start, (index) => values[start + index]);

    if (fillWith != null && i >= withExtra) {
      tmp.add(fillWith);
    }

    result.add(tmp);
  }

  return result;
}

String doString(Object? value) {
  return '$value';
}

num doSum(Environment environment, Iterable<Object?> values,
    {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<Object?>(makeAttributeGetter(environment, attribute));
  }

  return values.cast<num>().fold<num>(start, (s, n) => s + n);
}

String doTrim(String value, [String? characters]) {
  if (characters == null) {
    return value.trim();
  }

  final left = RegExp('^[$characters]+', multiLine: true);
  final right = RegExp('[$characters]+\$', multiLine: true);
  return value.replaceAll(left, '').replaceAll(right, '');
}

String doUpper(String value) {
  return value.toUpperCase();
}

int doWordCount(String string) {
  final matches = RegExp(r'\w+').allMatches(string);
  return matches.length;
}

String doWordWrap(Environment environment, String string, int width,
    {bool breakLongWords = true,
    String? wrapString,
    bool breakOnHyphens = true}) {
  final wrapper = TextWrapper(
      width: width,
      expandTabs: false,
      replaceWhitespace: false,
      breakLongWords: breakLongWords,
      breakOnHyphens: breakOnHyphens);
  wrapString ??= environment.newLine;
  return const LineSplitter()
      .convert(string)
      .map<String>((line) => wrapper.wrap(line).join(wrapString!))
      .join(wrapString);
}

const Map<String, Function> filters = {
  'abs': doAbs,
  'attr': doAttribute,
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
  'join': doJoin,
  'last': doLast,
  'length': count,
  'list': list,
  'lower': doLower,
  'pprint': doPPrint,
  'random': doRandom,
  'replace': doReplace,
  'reverse': doReverse,
  'safe': doMarkSafe,
  'slice': doSlice,
  'string': doString,
  'sum': doSum,
  'trim': doTrim,
  'upper': doUpper,
  'wordcount': doWordCount,
  'wordwrap': doWordWrap,

  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'round': doRound,
  // 'select': doSelect,
  // 'selectattr': doSelectAttr,
  // 'sort': doSort,
  // 'striptags': doStripTags,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'xmlattr': doXMLAttr,
};

const Set<String> contextFilters = {'join'};

const Set<String> environmentFilters = {'attr', 'random', 'sum', 'wordwrap'};
