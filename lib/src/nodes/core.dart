import '../context.dart';
import '../markup.dart';
import '../utils.dart';

export '../context.dart';
export '../utils.dart';

abstract class Node {
  void accept(StringSink outSink, Context context);

  String toDebugString([int level = 0]);
}

abstract class Statement extends Node {}

abstract class Expression extends Node {
  Object resolve(Context context) => null;

  /// This method takes a [StringSink] object (usually a [StringBuffer]) and a [Context] object
  /// and either finalizes and writes the resolved value to the sink
  /// or runs the accept method on the received [Node] again.
  /// Regarding [environment.finalize the official docs say the following:
  ///
  /// finalize
  //
  //  A callable that can be used to process the result of a variable expression before it is output. For example one can convert None implicitly into an empty string here.
  ///
  /// Source: https://jinja.palletsprojects.com/en/2.11.x/api/#jinja2.Environment .
  @override
  void accept(StringSink outSink, Context context) {
    var value = resolve(context);

    if (value is Node) {
      value.accept(outSink, context);
    } else {
      value = context.environment.finalize(value);

      if (context.environment.autoEscape) {
        value = Markup.escape(value.toString());
      }

      outSink.write(value);
    }
  }
}

abstract class UnaryExpression extends Expression {
  Expression get expr;
  String get symbol;

  @override
  String toDebugString([int level = 0]) {
    return '${' ' * level}$symbol${expr.toDebugString()}';
  }
}

abstract class BinaryExpression extends Expression {
  Expression get left;
  Expression get right;
  String get symbol;

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('${left.toDebugString()} $symbol ${right.toDebugString()}');
    return buffer.toString();
  }
}

abstract class CanAssign {
  List<String> get keys;

  bool get canAssign {
    return false;
  }
}

class Name extends Expression implements CanAssign {
  Name(this.name);

  final String name;

  /// At it´s  core this method is just a simple getter for variables passed by the user.
  /// Additionally, if checking the variables fails, it falls back to searching global variables
  /// and if this fails too, it returns [environment.undefined], an empty class with an empty string representation (see `runtime.dart`).
  /// This is done by operator overloading of the index operator in `context.dart`.
  /// From the official docs: "Additionally there is a resolve() method that doesn’t fail with a KeyError but returns an Undefined object for missing variables."
  /// Source: https://jinja.palletsprojects.com/en/2.11.x/api/?highlight=context#the-context
  @override
  dynamic resolve(Context context) {
    return context[name];
  }

  @override
  bool get canAssign {
    return true;
  }

  @override
  List<String> get keys {
    return <String>[name];
  }

  @override
  String toDebugString([int level = 0]) {
    return ' ' * level + name;
  }

  @override
  String toString() {
    return 'Name($name)';
  }
}

class Literal<T> extends Expression {
  Literal(this.value);

  final T value;

  @override
  T resolve(Context context) {
    return value;
  }

  @override
  String toDebugString([int level = 0]) {
    return ' ' * level + repr(value);
  }

  @override
  String toString() {
    return 'Literal($value)';
  }
}
