import 'dart:math';
import 'dart:mirrors';

import 'runtime.dart';

bool asBool(value) {
  if (value is Undefined) return false;
  if (value is bool) return value;
  if (value is num) return value != 0.0;
  if (value is String) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return value != null;
}

getAttr(value, String attributes) {
  var attributeValue = value;
  for (final attribute in attributes.split('.'))
    if (attributeValue is Map)
      attributeValue = attributeValue[attribute];
    else
      attributeValue =
          reflect(attributeValue).getField(Symbol(attribute)).reflectee;
  return attributeValue;
}

bool isNull(value) => value == null;

List<int> range(int n) => List<int>.generate(n, (i) => i);

int randomInt(int max) => Random(DateTime.now().microsecond).nextInt(max);

String rprint(value) => value.toString().replaceAll(RegExp(r'\r\n|\n'), r'\n');
