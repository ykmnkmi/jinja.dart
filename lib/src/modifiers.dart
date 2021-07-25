import 'nodes.dart';

void namespace(Node node) {
  if (node is Call) {
    if (node.expression is Name &&
        (node.expression as Name).name == 'namespace') {
      final arguments =
          node.arguments == null ? <Expression>[] : node.arguments!.toList();
      node.arguments = null;

      if (node.keywordArguments != null && node.keywordArguments!.isNotEmpty) {
        final dict = DictLiteral(node.keywordArguments!
            .map<Pair>(
                (keyword) => Pair(Constant<String>(keyword.key), keyword.value))
            .toList());
        node.keywordArguments = null;
        arguments.add(dict);
      }

      if (node.dynamicArguments != null) {
        arguments.add(node.dynamicArguments!);
        node.dynamicArguments = null;
      }

      if (node.dynamicKeywordArguments != null) {
        arguments.add(node.dynamicKeywordArguments!);
        node.dynamicKeywordArguments = null;
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
      final arguments =
          node.arguments == null ? <Expression>[] : node.arguments!.toList();
      node.arguments = null;

      if (node.keywordArguments != null && node.keywordArguments!.isNotEmpty) {
        final dict = DictLiteral(node.keywordArguments!
            .map<Pair>(
                (keyword) => Pair(Constant<String>(keyword.key), keyword.value))
            .toList());
        node.keywordArguments = null;
        arguments.add(dict);
      }

      if (node.dynamicArguments != null) {
        arguments.add(node.dynamicArguments!);
        node.dynamicArguments = null;
      }

      if (node.dynamicKeywordArguments != null) {
        arguments.add(node.dynamicKeywordArguments!);
        node.dynamicKeywordArguments = null;
      }

      if (arguments.isNotEmpty) {
        node.arguments = <Expression>[ListLiteral(arguments)];
      }

      return;
    }
  }

  node.visitChildNodes(namespace);
}
