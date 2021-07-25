import 'modifiers.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'utils.dart';

export 'filters.dart' show contextFilters, environmentFilters, filters;
export 'tests.dart' show tests;

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

const Map<String, Object?> globals = <String, Object?>{
  'namespace': NameSpace.factory,
  'list': list,
  'range': range,
};

const List<NodeVisitor> modifiers = <NodeVisitor>[
  namespace,
];

Object? finalize(Object? value) {
  return value;
}

Object? fieldGetter(Object? object, String field) {
  throw NoSuchMethodError.withInvocation(
      object, Invocation.getter(Symbol(field)));
}

Undefined undefined({String? hint, Object? object, String? name}) {
  return Undefined(hint: hint, object: object, name: name);
}
