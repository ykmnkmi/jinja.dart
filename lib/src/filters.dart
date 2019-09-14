import 'dart:math';

import 'markup.dart';
import 'undefined.dart';
import 'utils.dart';

const Map<String, Function> filters = <String, Function>{
  'abs': doAbs,
  'attr': doAttr,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': doCount,
  'd': doDefault,
  'default': doDefault,
  'e': doEscape,
  'escape': doEscape,
  'first': doFirst,
  'float': doFloat,
  'forceescape': doForceEscape,
  'int': doInt,
  'join': doJoin,
  'last': doLast,
  'length': doCount,
  'list': doList,
  'lower': doLower,
  'random': doRandom,
  'string': doString,
  'sum': doSum,
  'trim': doTrim,
  'upper': doUpper,

  // 'batch': doBatch,
  // 'dictsort': doDictSort,
  // 'filesizeformat': doFileSizeFormat,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
  // 'pprint': doPPrint,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'replace': doReplace,
  // 'reverse': doReverse,
  // 'round': doRound,
  // 'safe': doMarkSafe,
  // 'select': doSelect,
  // 'selectattr': doSelectAttr,
  // 'slice': doSlice,
  // 'sort': doSort,
  // 'striptags': doStripTags,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'wordcount': doWordCount,
  // 'wordwrap': doWordwrap,
  // 'xmlattr': doXMLAttr,
};

num doAbs(num n) => n.abs();

dynamic doAttr(dynamic value, String attribute) =>
    tryGetField(value, attribute) ?? tryGetItem(value, attribute);

String doCapitalize(String value) =>
    value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();

String doCenter(String value, int width) {
  if (value.length >= width) return value;
  final padLength = (width - value.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + value + pad;
}

int doCount(dynamic value) {
  try {
    return value.length as int;
  } catch (e) {
    return null;
  }
}

dynamic doDefault(dynamic value, [dynamic d = '', bool boolean = false]) {
  if (boolean) return toBool(value) ? value : d;
  return value is! Undefined ? value : d;
}

Markup doEscape(value) =>
    value is Markup ? value : Markup.escape(value.toString());

dynamic doFirst(Iterable values) => values.first;

double doFloat(dynamic value, [double $default = 0.0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? $default;
}

Markup doForceEscape(value) => Markup.escape(value.toString());

int doInt(dynamic value, [int $default = 0, int base = 10]) {
  if (value is num) return value.toInt();
  return int.tryParse(value.toString(), radix: base) ?? $default;
}

String doJoin(Iterable values, [String d = '', String attribute]) {
  if (attribute != null) {
    return values.map((value) => doAttr(value, attribute)).join(d);
  }

  return values.join(d);
}

dynamic doLast(Iterable values) => values.last;

List doList(dynamic value) {
  if (value is Iterable) return value.toList();
  if (value is String) return value.split('');
  return [value];
}

String doLower(dynamic value) => repr(value, false).toLowerCase();

dynamic doRandom(List values) {
  final length = values.length;
  return values[Random(DateTime.now().millisecondsSinceEpoch).nextInt(length)];
}

String doString(dynamic value) => repr(value, false);

num doSum(Iterable values, {String attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map((val) => doAttr(val, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String doTrim(dynamic value) => repr(value, false).trim();

String doUpper(dynamic value) => repr(value, false).toUpperCase();
