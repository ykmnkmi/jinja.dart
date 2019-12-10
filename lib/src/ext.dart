import 'nodes.dart';
import 'parser.dart';

typedef ExtensionParser<T extends Node> = T Function(Parser parser);

abstract class Extension {
  Set<String> get tags;

  Node parse(Parser parser);
}
