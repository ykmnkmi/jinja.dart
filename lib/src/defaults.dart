import 'filters.dart';
import 'nodes.dart';
import 'parser.dart';
import 'tests.dart';
import 'utils.dart';

const Map<String, ParserCallback> defaultExtensions = <String, ParserCallback>{
  'block': BlockStatement.parse,
  'extends': ExtendsStatement.parse,
  'filter': FilterBlockStatement.parse,
  'for': ForStatement.parse,
  'if': IfStatement.parse,
  'include': IncludeStatement.parse,
  'raw': RawStatement.parse,
  'set': SetStatement.parse,
};

const List<String> defaultKeywords = <String>[
  // Expressions
  'and',
  'or',
  'not'
  'if',
  'is',
  'in',
];

const Map<String, dynamic> defaultContext = <String, dynamic>{
  'range': range,
};

const Map<String, Function> defaultFilters = filters;
const Map<String, Function> defaultTests = tests;
