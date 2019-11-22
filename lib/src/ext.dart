import 'nodes.dart';
import 'parser.dart';

typedef T ExtensionParser<T extends Node>(Parser parser);

abstract class Extension {
  Set<String> get tags;

  Node parse(Parser parser);
}

