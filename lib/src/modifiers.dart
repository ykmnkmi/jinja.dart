import 'package:jinja/src/nodes.dart';
import 'package:jinja/src/visitor.dart';

/// Modifies Template AST from `map('filter', *args, **kwargs)`
/// to `map(null, attribute=..., default, positional=args, named=kwargs)`
/// to match [doMap] definition.
void mapModifier(Node node) {
  for (var filter in node.findAll<Filter>()) {
    if (filter.name == 'map') {
      var arguments = filter.arguments;
      filter.arguments = <Expression>[arguments[0]];

      var keywords = filter.keywords;
      filter.keywords = <Keyword>[];

      var positional = <Expression>[];
      var named = <Pair>[];

      if (arguments.length == 1) {
        filter.keywords.add(Keyword('filter', Constant(null)));
      } else {
        filter.keywords.add(Keyword('filter', arguments[1]));
        positional.addAll(arguments.skip(2));
      }

      for (var keyword in keywords) {
        switch (keyword.key) {
          case 'attribute':
          case 'defaultValue':
            filter.keywords.add(keyword);
            break;
          default:
            named.add(Pair(Constant(keyword.key), keyword.value));
        }
      }

      filter.keywords
        ..add(Keyword('positional', Array(positional)))
        ..add(Keyword('named', Dict(named)));
    }
  }
}

/// Modifies Template AST from `namespace(map1, ..., key1=value1, ...)`
/// to `namespace([map1, ..., {'key1': value1, ...}])`, to match [namespace]
/// definition.
void namespaceModifier(Node node) {
  for (var call in node.findAll<Call>()) {
    var expression = call.expression;

    if (expression is! Name || expression.name != 'namespace') {
      continue;
    }

    var arguments = <Expression>[...call.arguments];
    call.arguments = <Expression>[];

    var keywords = call.keywords;

    if (keywords.isNotEmpty) {
      var pairs = keywords.map((keyword) => keyword.toPair()).toList();
      arguments.add(Dict(pairs));
      call.keywords = <Keyword>[];
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

/// Modifies Template AST from `self.block()` to `self['block']()`.
void selfModifier(Node node) {
  Expression mapper(Expression expression) {
    if (expression is Attribute) {
      var value = expression.value;

      if (value is Name && (value.name == 'self')) {
        return Item.string(expression.attribute, value);
      }
    }

    return expression;
  }

  node.accept(const ExpressionMapper(), mapper);
}

/// Modifies Template AST from `loop.last` to `loop['last']` and from
/// `loop.cycle(first, second, *list)` to `loop.cycle([first, second], list)`,
/// to match [LoopContext.cycle] definition.
void loopModifier(Node node) {
  Expression cycle(Expression expression) {
    if (expression is Call) {
      var argument = expression.expression;

      if (argument is Attribute) {
        var value = argument.value;

        if (value is Name &&
            value.name == 'loop' &&
            argument.attribute == 'cycle') {
          var arguments = expression.arguments;

          if (arguments != null) {
            arguments = <Expression>[Array(arguments)];
            expression.arguments = arguments;

            var dArguments = expression.dArguments;

            if (dArguments != null) {
              arguments.add(dArguments);
              expression.dArguments = null;
            }
          }
        }
      }

      return expression;
    }

    return expression;
  }

  node.accept(const ExpressionMapper(), cycle);

  Expression attribute(Expression expression) {
    if (expression is Attribute) {
      var value = expression.value;

      if (value is Name && (value.name == 'loop')) {
        return Item.string(expression.attribute, value);
      }
    }

    return expression;
  }

  node.accept(const ExpressionMapper(), attribute);
}

// TODO: move to RuntimeCompiler
const List<NodeVisitor> modifiers = <NodeVisitor>[
  mapModifier,
  namespaceModifier,
  selfModifier,
  loopModifier,
];
