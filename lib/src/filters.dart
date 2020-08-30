import 'dart:math' show Random, pow;

import 'environment.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

typedef AttrGetter = dynamic Function(dynamic object);

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
    {dynamic Function(dynamic)? postProcess, dynamic d}) {
  final attributes = prepareAttributeParts(attribute);

  final attributeGetter = (item) {
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
  };

  return attributeGetter;
}

List<String> prepareAttributeParts(String attribute) {
  return attribute.split('.');
}

num doAbs(num n) {
  return n.abs();
}

dynamic doAttr(Environment environment, dynamic value, String attribute) {
  try {
    return environment.getItem(value, attribute) ??
        environment.getField(value, attribute) ??
        environment.undefined;
  } catch (_) {
    return environment.undefined;
  }
}

Iterable<List> doBatch(Iterable values, int lineCount,
    [Object? fillWith]) sync* {
  var tmp = [];

  for (final item in values) {
    if (tmp.length == lineCount) {
      yield tmp;
      tmp = [];
    }

    tmp.add(item);
  }

  if (tmp.isNotEmpty) {
    if (fillWith != null) {
      tmp.addAll(List.filled(lineCount - tmp.length, fillWith));
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

int? doCount(dynamic value) {
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

dynamic doDefault(dynamic value, [dynamic d = '', bool boolean = false]) {
  if (boolean) {
    return toBool(value) ? value : d;
  }

  return value is! Undefined ? value : d;
}

Markup doEscape(dynamic value) {
  return value is Markup ? value : Markup.escape(value.toString());
}

String doFileSizeFormat(dynamic value, [bool binary = false]) {
  final bytes =
      value is num ? value.toDouble() : double.parse(value.toString());
  final base = binary ? 1024 : 1000;

  const prefixes = <List<String>>[
    <String>['KiB', 'kB'],
    <String>['MiB', 'MB'],
    <String>['GiB', 'GB'],
    <String>['TiB', 'TB'],
    <String>['PiB', 'PB'],
    <String>['EiB', 'EB'],
    <String>['ZiB', 'ZB'],
    <String>['YiB', 'YB'],
  ];

  if (bytes == 1.0) {
    return '1 Byte';
  } else if (bytes < base) {
    final size = bytes.toStringAsFixed(1);
    return size.endsWith('.0')
        ? size.substring(0, size.length - 2)
        : size + ' Bytes';
  } else {
    final k = binary ? 0 : 1;
    late num unit;

    for (var i = 0; i < prefixes.length; i++) {
      unit = pow(base, i + 2);

      if (bytes < unit) {
        final size = (base * bytes / unit).toStringAsFixed(1);
        return '$size ${prefixes[i][k]}';
      }
    }

    final size = (base * bytes / unit).toStringAsFixed(1);
    return '$size ${prefixes.last[k]}';
  }
}

dynamic doFirst(Iterable values) {
  return values.first;
}

double doFloat(dynamic value, [double d = 0.0]) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? d;
}

Markup doForceEscape(dynamic value) {
  return Markup.escape(value.toString());
}

int doInt(dynamic value, [int d = 0, int base = 10]) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString(), radix: base) ?? d;
}

String doJoin(Environment environment, Iterable values,
    [String d = '', String? attribute]) {
  if (attribute != null) {
    return values.map(makeAttribute(environment, attribute)).join(d);
  }

  return values.join(d);
}

dynamic doLast(Iterable values) {
  return values.last;
}

List doList(dynamic value) {
  if (value is Iterable) {
    return value.toList();
  }

  if (value is String) {
    return value.split('');
  }

  return [value];
}

String doLower(dynamic value) {
  return repr(value, false).toLowerCase();
}

dynamic doRandom(Environment environment, List values) {
  final length = values.length;
  return values[environment.random.nextInt(length)];
}

String doString(dynamic value) {
  return repr(value, false);
}

num doSum(Environment environment, Iterable values,
    {String? attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map(makeAttribute(environment, attribute));
  }

  return values.cast<num>().fold(start, (s, n) => s + n);
}

String doTrim(dynamic value) {
  return repr(value, false).trim();
}

String doUpper(dynamic value) {
  return repr(value, false).toUpperCase();
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
