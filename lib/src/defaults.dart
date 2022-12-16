import 'package:jinja/src/context.dart';
import 'package:jinja/src/namespace.dart';
import 'package:jinja/src/utils.dart';

export 'package:jinja/src/filters.dart' show filters;
export 'package:jinja/src/modifiers.dart' show modifiers;
export 'package:jinja/src/tests.dart' show tests;

const String blockStart = '{%';
const String blockEnd = '%}';
const String variableStart = '{{';
const String variableEnd = '}}';
const String commentStart = '{#';
const String commentEnd = '#}';
const String? lineCommentPrefix = null;
const String? lineStatementPrefix = null;
const bool trimBlocks = false;
const bool lStripBlocks = false;
const String newLine = '\n';
const bool keepTrailingNewLine = false;
const bool optimize = true;
const bool autoEscape = false;
const bool autoReload = true;
const int leeway = 5;

const Map<String, Object?> globals = <String, Object?>{
  'namespace': Namespace.factory,
  'list': list,
  'print': print,
  'range': range,
};

Object finalize(Context context, Object? value) {
  return value ?? '';
}

Object? getItem(dynamic value, Object? item) {
  try {
    // TODO: dynamic invocation
    // ignore: avoid_dynamic_calls
    return value[item];
  } on NoSuchMethodError {
    if (value == null) {
      rethrow;
    }

    return null;
  }
}
