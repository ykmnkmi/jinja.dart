import 'filters.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'tests.dart';
import 'utils.dart';

final Map<String, Function> defaultFilters = filters;

final Map<String, Function> defaultTests = tests;

final Map<String, Object?> defaultContext = <String, Object?>{
  'namespace': namespace,
  'range': range,
};
