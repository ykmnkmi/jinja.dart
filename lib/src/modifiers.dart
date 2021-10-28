import 'nodes.dart';

void cycle(Node node) {
  if (node is Call) {
    var expression = node.expression;

    if (expression is Attribute && expression.attribute == 'cycle') {
      var arguments = node.arguments;

      if (arguments != null) {
        node.arguments = arguments = <Expression>[Array(arguments)];

        var dArguments = node.dArguments;

        if (dArguments != null) {
          arguments.add(dArguments);
          node.dArguments = null;
        }
      }

      return;
    }
  }

  node.visitChildrens(cycle);
}

void namespace(Node node) {
  if (node is Call) {
    var expression = node.expression;

    if (expression is Name && expression.name == 'namespace') {
      var arguments = <Expression>[...?node.arguments];
      node.arguments = null;
      var keywords = node.keywords;

      if (keywords != null && keywords.isNotEmpty) {
        var pairs = List<Pair>.generate(
            keywords.length, (index) => keywords[index].toPair());

        arguments.add(Dict(pairs));
        node.keywords = null;
      }

      var dArguments = node.dArguments;

      if (dArguments != null) {
        arguments.add(dArguments);
        node.dArguments = null;
      }

      var dKeywordArguments = node.dKeywords;

      if (dKeywordArguments != null) {
        arguments.add(dKeywordArguments);
        node.dKeywords = null;
      }

      if (arguments.isNotEmpty) {
        node.arguments = <Expression>[Array(arguments)];
      }

      return;
    }
  }

  node.visitChildrens(namespace);
}
