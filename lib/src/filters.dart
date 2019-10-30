import 'dart:math' show Random;

import 'environment.dart';
import 'markup.dart';
import 'undefined.dart';
import 'utils.dart';

const Map<String, Function> envFilters = <String, Function>{
  'attr': doAttr,
  'join': doJoin,
  'sum': doSum,
};

const Map<String, Function> filters = <String, Function>{
  'abs': doAbs,
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
  'last': doLast,
  'length': doCount,
  'list': doList,
  'lower': doLower,
  'random': doRandom,
  'string': doString,
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

Object doAttr(Environment env, Object value, String attribute) {
  return env.getItem(value, attribute) ?? env.getField(value, attribute);
}

String doCapitalize(String value) =>
    value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();

String doCenter(String value, int width) {
  if (value.length >= width) return value;
  int padLength = (width - value.length) ~/ 2;
  String pad = ' ' * padLength;
  return pad + value + pad;
}

int doCount(Object value) {
  if (value is String) return value.length;
  if (value is Iterable) return value.length;
  if (value is Map) return value.length;
  return null;
}

Object doDefault(Object value, [Object $default = '', bool boolean = false]) {
  if (boolean) return toBool(value) ? value : $default;
  return value is! Undefined ? value : $default;
}

Markup doEscape(Object value) =>
    value is Markup ? value : Markup.escape(value.toString());

Object doFirst(Iterable<Object> values) => values.first;

double doFloat(Object value, [double $default = 0.0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? $default;
}

Markup doForceEscape(Object value) => Markup.escape(value.toString());

int doInt(Object value, [int $default = 0, int base = 10]) {
  if (value is num) return value.toInt();
  return int.tryParse(value.toString(), radix: base) ?? $default;
}

String doJoin(Environment env, Iterable<Object> values,
    [String d = '', String attribute]) {
  if (attribute != null) {
    return values.map((Object value) => doAttr(env, value, attribute)).join(d);
  }

  return values.join(d);
}

Object doLast(Iterable<Object> values) => values.last;

List<Object> doList(Object value) {
  if (value is Iterable) return value.toList();
  if (value is String) return value.split('');
  return <Object>[value];
}

String doLower(Object value) => repr(value, false).toLowerCase();

final Random _rnd = Random();
Object doRandom(List<Object> values) {
  int length = values.length;
  return values[_rnd.nextInt(length)];
}

String doString(Object value) => repr(value, false);

num doSum(Environment env, Iterable<Object> values,
    {String attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<Object>((Object val) => doAttr(env, val, attribute));
  }

  return values.cast<num>().fold<num>(start, (num s, num n) => s + n);
}

String doTrim(Object value) => repr(value, false).trim();

String doUpper(Object value) => repr(value, false).toUpperCase();
