import '../core.dart';

class Name extends Expression implements Assignable {
  Name(this.name);

  final String name;

  @override
  dynamic resolve(Context context) => context[name];

  @override
  bool get canAssign => true;

  @override
  List<String> get keys => <String>[name];

  @override
  String toDebugString([int level = 0]) => ' ' * level + name;

  @override
  String toString() => 'Name($name)';
}

class Literal extends Expression {
  Literal(this.value);

  final dynamic value;

  @override
  dynamic resolve(Context context) => value;

  @override
  String toDebugString([int level = 0]) => ' ' * level + repr(value);

  @override
  String toString() => 'Literal($value)';
}

class ListExpression extends Expression {
  ListExpression(this.values);

  final List<Expression> values;

  @override
  List resolve(Context context) =>
      values.map((value) => value.resolve(context)).toList(growable: false);

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level +
      '[${values.map((value) => value.toDebugString()).join(', ')}]';

  @override
  String toString() => 'ListExpression($values)';
}

class MapExpression extends Expression {
  MapExpression(this.values);

  final Map<Expression, Expression> values;

  @override
  Map resolve(Context context) => values.map(
      (key, value) => MapEntry(key.resolve(context), value.resolve(context)));

  @override
  String toDebugString([int level = 0]) {
    var buffer = StringBuffer(' ' * level);

    values.forEach((key, value) {
      buffer.write(key.toDebugString());
      buffer.write(': ');
      buffer.write(value.toDebugString());
    });

    return buffer.toString();
  }

  @override
  String toString() => 'MapExpression($values)';
}

class TupleExpression extends Expression implements Assignable {
  TupleExpression(this.items);

  final List<Expression> items;

  @override
  List resolve(Context context) =>
      items.map((value) => value.resolve(context)).toList(growable: false);

  @override
  bool get canAssign => items.any((item) => item is Name);

  @override
  List<String> get keys =>
      items.map((item) => (item as Name).name).toList(growable: false);

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level + '(${items.map((item) => item.toDebugString()).join(', ')})';

  @override
  String toString() => 'TupleExpression($items)';
}
