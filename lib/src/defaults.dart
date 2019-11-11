import 'filters.dart';
import 'nodes.dart';
import 'runtime.dart';
import 'tests.dart';
import 'utils.dart';

const Map<String, Function> defaultEnvFilters = envFilters;
const Map<String, Function> defaultFilters = filters;
const Map<String, Function> defaultTests = tests;

final Map<String, Object> defaultContext = <String, Object>{
  'namespace': NameSpace.namespace,
  'range': range,
};
