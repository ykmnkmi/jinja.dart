import 'filters.dart';
import 'namespace.dart';
import 'nodes.dart';
import 'tests.dart';
import 'utils.dart';

const Map<String, dynamic> defaultContext = <String, dynamic>{
  'namespace': const NameSpaceWrapper(),
  'range': range,
};

const Map<String, Function> defaultFilters = filters;
const Map<String, Function> defaultTests = tests;
