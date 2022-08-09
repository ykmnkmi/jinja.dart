import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

/// Modifies [TemplateNode] AST from `loop.cycle(first, second, *list)`
/// to `loop.cycle([first, second], list)`, to match [LoopContext.cycle] definition.
void loopCycleModifier(Node node) {
  for (var call in node.findAll<Call>()) {
    var expression = call.expression;

    if (expression is! Attribute) {
      continue;
    }

    var value = expression.value;

    if (value is Name &&
        value.name == 'loop' &&
        expression.attribute == 'cycle') {
      var arguments = call.arguments;

      if (arguments != null) {
        call.arguments = arguments = <Expression>[Array(arguments)];

        var dArguments = call.dArguments;

        if (dArguments != null) {
          arguments.add(dArguments);
          call.dArguments = null;
        }
      }
    }
  }
}

/// Modifies [TemplateNode] AST from `namespace(map1, ..., key1=value1, ...)`
/// to `namespace([map1, ..., {'key1': value1, ...}])`, to match [namespace] definition.
void namespaceModifier(Node node) {
  for (var call in node.findAll<Call>()) {
    var expression = call.expression;

    if (expression is! Name || expression.name != 'namespace') {
      continue;
    }

    var arguments = <Expression>[...?call.arguments];
    call.arguments = null;

    var keywords = call.keywords;

    if (keywords != null && keywords.isNotEmpty) {
      var pairs =
          List<Pair>.generate(keywords.length, (i) => keywords[i].toPair());
      arguments.add(Dict(pairs));
      call.keywords = null;
    }

    var dArguments = call.dArguments;

    if (dArguments != null) {
      arguments.add(dArguments);
      call.dArguments = null;
    }

    var dKeywordArguments = call.dKeywords;

    if (dKeywordArguments != null) {
      arguments.add(dKeywordArguments);
      call.dKeywords = null;
    }

    if (arguments.isNotEmpty) {
      call.arguments = <Expression>[Array(arguments)];
    }
  }
}

void attributeToItemModifier(Node node) {
  Expression mapper(Expression expression) {
    if (expression is Attribute) {
      var value = expression.value;

      if (value is Name && (value.name == 'loop' || value.name == 'self')) {
        return Item.string(expression.attribute, value);
      }
    }

    return expression;
  }

  node.accept(const ExpressionMapper(), mapper);
}

// TODO: move to RuntimeCompiler
const List<NodeVisitor> modifiers = <NodeVisitor>[
  loopCycleModifier,
  namespaceModifier,
  attributeToItemModifier,
];
