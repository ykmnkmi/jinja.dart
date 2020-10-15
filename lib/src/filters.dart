import 'dart:math' show pow;

import 'environment.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

typedef AttrGetter = Object? Function(Object? object);

enum FilterType {
  context,
  environment,
}

final Expando<FilterType> _filterTypes = Expando<FilterType>();

Function asContextFilter(Function filter) {
  _filterTypes[filter] = FilterType.context;
  return filter;
}

Function asEnvironmentFilter(Function filter) {
  _filterTypes[filter] = FilterType.environment;
  return filter;
}

FilterType? getFilterType(Function filter) {
  return _filterTypes[filter];
}

AttrGetter makeAttribute(Environment environment, String attribute,
    {Object? Function(Object?)? postProcess, Object? d}) {
  final attributes = prepareAttributeParts(attribute);

  Object? attributeGetter(Object? item) {
    for (final part in attributes) {
      item = doAttr(environment, item, part);

      if (item is Undefined) {
        if (d != null) {
          item = d;
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

List<String> prepareAttributeParts(String attribute) {
  return attribute.split('.');
}

num doAbs(num n) {
  return n.abs();
}

Object? doAttr(Environment environment, Object? value, String attribute) {
  try {
    return environment.getItem(value, attribute) ??
        environment.getField(value, attribute) ??
        environment.undefined;
  } catch (_) {
    return environment.undefined;
  }
}

Iterable<List<Object?>> doBatch(Iterable<Object?> values, int lineCount,
    [Object? fillWith]) sync* {
  var tmp = <Object?>[];

  for (final item in values) {
    if (tmp.length == lineCount) {
      yield tmp;
      tmp = <Object?>[];
    }

    tmp.add(item);
  }

  if (tmp.isNotEmpty) {
    if (fillWith != null) {
      tmp.addAll(List<Object>.filled(lineCount - tmp.length, fillWith));
    }

    yield tmp;
  }
}

String doCapitalize(String value) {
  return value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();
}

String doCenter(String value, int width) {
  if (value.length >= width) {
    return value;
  }

  final padLength = (width - value.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + value + pad;
}

int? doCount(Object? value) {
  if (value is String) {
    return value.length;
  }

  if (value is Iterable) {
    return value.length;
  }

  if (value is Map) {
    return value.length;
  }

  return null;
}

Object doDefault(Object? value, [Object d = '', bool boolean = false]) {
  if (boolean) {
    return toBool(value) ? value! : d;
  }

  return value is Undefined ? d : value!;
}

Markup doEscape(Object value) {
  return value is Markup ? value : Markup.escape(value.toString());
}

String doFileSizeFormat(Object value, [bool binary = false]) {
  final base = binary ? 1024 : 1000;

  double bytes;

  if (value is double) {
    bytes = value;
  } else if (value is int) {
    bytes = value.toDouble();
  } else if (value is String) {
    bytes = double.parse(value);
  } else {
    // TODO: add message
    throw Exception();
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
    const suffixes = [
      [' KiB', ' kB'],
      [' MiB', ' MB'],
      [' GiB', ' GB'],
      [' TiB', ' TB'],
      [' PiB', ' PB'],
      [' EiB', ' EB'],
      [' ZiB', ' ZB'],
      [' YiB', ' YB'],
    ];

    final k = binary ? 0 : 1;
    late num unit;

    for (var i = 0; i < suffixes.length; i++) {
      unit = pow(base, i + 2);

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

double doFloat(Object? value, [double d = 0.0]) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? d;
  }

  // TODO: add message
  throw Exception();
}

Markup doForceEscape(Object value) {
  return Markup.escape(value.toString());
}

int doInt(Object? value, [int d = 0, int base = 10]) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.toString(), radix: base) ?? d;
  }

  // TODO: add message
  throw Exception();
}

String doJoin(Environment environment, Iterable<Object?> values,
    [String d = '', String? attribute]) {
  if (attribute != null) {
    return values.map(makeAttribute(environment, attribute)).join(d);
  }

  return values.join(d);
}

Object? doLast(Iterable<Object?> values) {
  return values.last;
}

List<Object?> doList(Object? value) {
  if (value is Iterable) {
    return value.toList();
  }

  if (value is String) {
    return value.split('');
  }

  return [value];
}

String doLower(String value) {
  return value.toLowerCase();
}

Object? doRandom(Environment environment, List<Object?> values) {
  final length = values.length;
  return values[environment.random.nextInt(length)];
}

String doString(Object? value) {
  if (value is String) {
    return value;
  }

  return repr(value);
}

num doSum(Environment environment, Iterable<Object?> values,
    {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map(makeAttribute(environment, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String doTrim(String value) {
  return value.trim();
}

String doUpper(String value) {
  return value.toUpperCase();
}

final Map<String, Function> filters = <String, Function>{
  'attr': asEnvironmentFilter(doAttr),
  'join': asEnvironmentFilter(doJoin),
  'sum': asEnvironmentFilter(doSum),
  'random': asEnvironmentFilter(doRandom),

  'abs': doAbs,
  'batch': doBatch,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': doCount,
  'd': doDefault,
  'default': doDefault,
  'e': doEscape,
  'escape': doEscape,
  'filesizeformat': doFileSizeFormat,
  'first': doFirst,
  'float': doFloat,
  'forceescape': doForceEscape,
  'int': doInt,
  'last': doLast,
  'length': doCount,
  'list': doList,
  'lower': doLower,
  'string': doString,
  'trim': doTrim,
  'upper': doUpper,

  // 'dictsort': doDictSort,
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
