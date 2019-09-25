import 'nodes.dart';
import 'parser.dart';

typedef T ExtensionParser<T extends Node>(Parser parser);

abstract class Extension {
  String get tag;

  Node parse(Parser parser);
}

