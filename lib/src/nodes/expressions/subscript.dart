import '../core.dart';

class Field extends Expression {
  Field(this.attr, this.expr);

  final String attr;
  final Expression expr;

  @override
  dynamic resolve(Context context) => getField(expr.resolve(context), attr);

  @override
  String toDebugString([int level = 0]) => '${expr.toDebugString(level)}.$attr';

  @override
  String toString() => 'Field($attr, $expr)';
}

class Item extends Expression {
  Item(this.item, this.expr);

  final Expression item;
  final Expression expr;

  @override
  dynamic resolve(Context context) =>
      getItem(expr.resolve(context), item.resolve(context));

  @override
  String toDebugString([int level = 0]) =>
      '${expr.toDebugString(level)}[${item.toDebugString()}]';

  @override
  String toString() => 'Item($item, $expr)';
}
