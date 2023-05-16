// TODO: move to RuntimeCompiler
library;

import 'package:jinja/src/nodes.dart';

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
          var arguments = <Expression>[Array(expression.arguments)];
          expression.arguments = arguments;

          var dArguments = expression.dArguments;

          if (dArguments != null) {
            arguments.add(dArguments);
            expression.dArguments = null;
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

void macroModifier(Node node) {}

const List<NodeVisitor> modifiers = <NodeVisitor>[
  namespaceModifier,
  selfModifier,
  loopModifier,
  macroModifier,
];
