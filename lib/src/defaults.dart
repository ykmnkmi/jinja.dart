import 'runtime.dart';
import 'utils.dart';

export 'filters.dart' show filters;
export 'tests.dart' show tests;
export 'modifiers.dart' show modifiers;

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

Object finalize(Object? value) {
  return value ?? '';
}

Object? getItem(dynamic object, Object? item) {
  try {
    // * dynamic invocation
    return object[item];
  } on NoSuchMethodError {
    if (object == null) {
      rethrow;
    }

    return null;
  }
}
