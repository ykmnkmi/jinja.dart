import 'dart:math';

import 'markup.dart';
import 'undefined.dart';
import 'utils.dart';

dynamic doAttr(dynamic value, String attribute) =>
    getItem(value, attribute) ?? getField(value, attribute);

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

dynamic doFirst(List values) => values.first;

Markup doForceEscape(value) => Markup.escape(value.toString());

String doJoin(Iterable values, [String separator = '', String attribute]) {
  if (attribute != null) {
    return values.map((value) => doAttr(value, attribute)).join(separator);
  }

  return values.join(separator);
}

dynamic doLast(List values) => values.last;

List doList(dynamic value) {
  if (value is Iterable) return value.toList();
  if (value is String) return value.split('');
  return [value];
}

String doLower(value) => value.toString().toLowerCase();

dynamic doRandom(List values) {
  final length = values.length;
  return values[Random(DateTime.now().millisecondsSinceEpoch).nextInt(length)];
}

String doString(value) => value.toString();

String doTrim(value) => value.toString().trim();

String doUpper(value) => value.toString().toUpperCase();

const Map<String, Function> filters = <String, Function>{
  // 'abs': doAbs,
  // 'batch': doBatch,
  // 'dictsort': doDictSort,
  // 'filesizeformat': doFileSizeFormat,
  // 'float': doFloat,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'int': doInt,
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
  // 'sum': doSum,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'wordcount': doWordCount,
  // 'wordwrap': doWordwrap,
  // 'xmlattr': doXMLAttr,

  'attr': doAttr,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': doCount,
  'd': doDefault,
  'default': doDefault,
  'e': doEscape,
  'escape': doEscape,
  'first': doFirst,
  'forceescape': doForceEscape,
  'join': doJoin,
  'last': doLast,
  'length': doCount,
  'list': doList,
  'lower': doLower,
  'random': doRandom,
  'string': doString,
  'trim': doTrim,
  'upper': doUpper,
};
