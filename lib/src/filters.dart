import 'dart:math';

import 'exceptions.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

int doLength(value) {
  if (value is Iterable) return value.length;
  if (value is Map) return value.length;
  if (value is String) return value.length;
  throw ArgumentError();
}

String doString(value) => value.toString();

Markup doEscape(value) =>
    value is Markup ? value : Markup.escape(value.toString());

Markup doForceEscape(value) => Markup.escape(value.toString());

String doUpper(value) => value.toString().toUpperCase();

String doLower(value) => value.toString().toLowerCase();

String doCapitalize(value) {
  final str = value.toString();
  return str.substring(0, 1).toUpperCase() + str.substring(1).toLowerCase();
}

List<List> doDictSort(Map values,
    {bool caseSensetive = false, String by = 'key', bool reverse = false}) {
  int pos;
  if (by == 'key')
    pos = 0;
  else if (by == 'value')
    pos = 1;
  else
    throw FilterArgumantException(
        'You can only sort by either "key" or "value"');

  final entries = values.entries
      .map<List>((entry) => [entry.key, entry.value])
      .toList(growable: false);

  entries.sort((first, second) {
    if (first == second) return 0;
    var f = first[pos], s = second[pos];
    if (!caseSensetive) {
      if (f is String) f = f.toLowerCase();
      if (s is String) s = s.toLowerCase();
    }
    if (f is Comparable && s is Comparable) return f.compareTo(s);
    final sorted = [f, s]..sort();
    if (first[pos] == sorted.last) return 1;
    return -1;
  });

  if (reverse) return entries.reversed.toList(growable: false);
  return entries;
}

doDefault(value, [defaultValue = '', bool boolean = false]) {
  if (boolean) return asBool(value) ? value : defaultValue;
  return value is! Undefined ? value : defaultValue;
}

String doJoin(Iterable values, [String separator = '', String attribute]) {
  if (attribute != null)
    return values.map((value) => getAttr(value, attribute)).join(separator);
  return values.join(separator);
}

String doCenter(value, int width) {
  final str = value.toString();
  if (str.length >= width) return str;
  final padLength = (width - str.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + str + pad;
}

doFirst(List values) => values.first;

doLast(List values) => values.last;

doRandom(List values) => values[randomInt(values.length)];

String doFileSizeFormat(value, [bool binary = false]) {
  final bytes = doFloat(value);
  final base = binary ? 1024 : 1000;
  final prefixes = <String>[
    binary ? 'KiB' : 'kB',
    binary ? 'MiB' : 'MB',
    binary ? 'GiB' : 'GB',
    binary ? 'TiB' : 'TB',
    binary ? 'PiB' : 'PB',
    binary ? 'EiB' : 'EB',
    binary ? 'ZiB' : 'ZB',
    binary ? 'YiB' : 'YB',
  ];

  if (bytes == 1)
    return '1 Byte';
  else if (bytes < base)
    return '${bytes.toInt()} Bytes';
  else {
    num unit;
    for (final prefix in prefixes) {
      unit = pow(base, prefixes.indexOf(prefix) + 2);
      if (bytes < unit)
        return '${(base * bytes / unit).toStringAsFixed(1)} $prefix';
    }
    return '${(base * bytes / unit).toStringAsFixed(1)} ${prefixes.last}';
  }
}

int doInt(value, [int defaultValue = 0, int radix = 10]) {
  if (value is num) return value.toInt();
  var str = value.toString().toLowerCase();
  if (str.startsWith('0x')) str = str.substring(2);
  return int.tryParse(str, radix: radix) ??
      double.tryParse(str)?.toInt() ??
      defaultValue;
}

double doFloat(value, [double defaultValue = 0.0]) => value is num
    ? value.toDouble()
    : double.tryParse(value.toString()) ?? defaultValue;

num doAbs(num value) => value.abs();

String doTrim(value) => value.toString().trim();

Iterable<List> doBatch(Iterable values, int lineCount, [fillWith]) sync* {
  final tmp = [];
  for (final item in values) {
    if (tmp.length == lineCount) {
      yield tmp.toList();
      tmp.clear();
    }
    tmp.add(item);
  }
  if (tmp.isNotEmpty) {
    if (fillWith != null && tmp.length < lineCount)
      tmp.addAll(List.filled(lineCount - tmp.length, fillWith));
    yield tmp;
  }
}

doSum(List values, [String attribute, num start = 0]) {
  if (attribute != null)
    return values
        .map((value) => getAttr(value, attribute))
        .fold(start, (prev, current) => prev + current);
  return values.fold(start, (prev, current) => prev + current);
}

List doList(value) {
  if (value is Iterable) return value.toList();
  if (value is String) return value.split('');
  return [value];
}

doAttr(value, String attribute) {
  if (value is Map) return value[attribute] ?? getAttr(value, attribute);
  return getAttr(value, attribute);
}

const filters = {
  'length': doLength,
  'count': doLength,
  'string': doString,
  // 'safe': doMarkSafe,
  'escape': doEscape,
  'e': doEscape,
  'forceescape': doForceEscape,
  // 'urlencode': doURLEncode,
  // 'replace': doReplace,
  'upper': doUpper,
  'lower': doLower,
  // 'xmlattr': doXMLAttr,
  'capitalize': doCapitalize,
  // 'title': doTitle,
  'dictsort': doDictSort,
  // 'sort': doSort,
  // 'unique': doUnique,
  // 'min': doMin,
  // 'max': doMax,
  'default': doDefault,
  'd': doDefault,
  'join': doJoin,
  'center': doCenter,
  'first': doFirst,
  'last': doLast,
  'random': doRandom,
  'filesizeformat': doFileSizeFormat,
  // 'pprint': doPPrint,
  // 'indent': doIndent,
  // 'urlize': doURLize,
  // 'truncate': doTruncate,
  // 'wordwrap': doWordwrap,
  // 'wordcount': doWordCount,
  'int': doInt,
  'float': doFloat,
  'abs': doAbs,
  // 'format': doFormat,
  'trim': doTrim,
  // 'striptags': doStripTags,
  // 'slice': doSlice,
  'batch': doBatch,
  // 'round': doRound,
  // 'groupby': doGroupBy,
  'sum': doSum,
  'list': doList,
  // 'reverse': doReverse,
  'attr': doAttr,
  // 'map': doMap,
  // 'select': doSelect,
  // 'reject': doReject,
  // 'selectattr': doSelectAttr,
  // 'rejectattr': doRejectAttr,
  // 'tojson': doToJson,
};
