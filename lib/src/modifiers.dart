import 'nodes.dart';

void namespace(Node node) {
  if (node is Call) {
    if (node.expression is Name &&
        (node.expression as Name).name == 'namespace') {
      final arguments = <Expression>[...?node.arguments];
      node.arguments = null;
      final keywords = node.keywordArguments;

      if (keywords != null && keywords.isNotEmpty) {
        final pairs = <Pair>[for (final keyword in keywords) keyword.toPair()];
        final dict = DictLiteral(pairs);
        node.keywordArguments = null;
        arguments.add(dict);
      }

      final dArguments = node.dArguments;

      if (dArguments != null) {
        arguments.add(dArguments);
        node.dArguments = null;
      }

      final dKeywordArguments = node.dKeywordArguments;

      if (dKeywordArguments != null) {
        arguments.add(dKeywordArguments);
        node.dKeywordArguments = null;
      }

      if (arguments.isNotEmpty) {
        node.arguments = <Expression>[ListLiteral(arguments)];
      }

      return;
    }
  }

  node.visitChildNodes(namespace);
}

void inheritance(Node node) {
  if (node is Call) {
    if (node.expression is Name && (node.expression as Name).name == 'super') {
      final arguments = <Expression>[...?node.arguments];
      node.arguments = null;

      final keywords = node.keywordArguments;

      if (keywords != null && keywords.isNotEmpty) {
        final pairs = <Pair>[for (final keyword in keywords) keyword.toPair()];
        final dict = DictLiteral(pairs);
        node.keywordArguments = null;
        arguments.add(dict);
      }

      if (node.dArguments != null) {
        arguments.add(node.dArguments!);
        node.dArguments = null;
      }

      if (node.dKeywordArguments != null) {
        arguments.add(node.dKeywordArguments!);
        node.dKeywordArguments = null;
      }

      if (arguments.isNotEmpty) {
        node.arguments = <Expression>[ListLiteral(arguments)];
      }

      return;
    }
  }

  node.visitChildNodes(namespace);
}
