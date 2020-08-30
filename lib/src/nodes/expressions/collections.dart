import '../core.dart';

class ListExpression extends Expression {
  ListExpression(this.values);

  final List<Expression> values;

  @override
  List resolve(Context context) {
    return values.map((value) => value.resolve(context)).toList();
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('[')
      ..writeAll(values.map((value) => value.toDebugString()), ',')
      ..write(']');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'ListExpression($values)';
  }
}

class MapExpression extends Expression {
  MapExpression(this.values);

  final Map<Expression, Expression> values;

  @override
  Map resolve(Context context) {
    return values.map(
        (key, value) => MapEntry(key.resolve(context), value.resolve(context)));
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);

    values.forEach((key, value) {
      buffer.write(key.toDebugString());
      buffer.write(': ');
      buffer.write(value.toDebugString());
    });

    return buffer.toString();
  }

  @override
  String toString() {
    return 'MapExpression($values)';
  }
}

class TupleExpression extends Expression implements CanAssign {
  TupleExpression(this.items);

  final List<Expression> items;

  @override
  List resolve(Context context) {
    return items.map((value) => value.resolve(context)).toList();
  }

  @override
  bool get canAssign {
    return items.every((item) => item is Name);
  }

  @override
  List<String> get keys {
    return items.map((item) => (item as Name).name).toList();
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level)
      ..write('[')
      ..writeAll(items.map((item) => item.toDebugString()), ', ')
      ..write(']');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'TupleExpression($items)';
  }
}
