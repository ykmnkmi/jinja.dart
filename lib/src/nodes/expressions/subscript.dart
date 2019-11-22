import '../../exceptions.dart';
import '../../runtime.dart';
import '../core.dart';

class Field extends Expression {
  Field(this.expr, this.attr);

  final Expression expr;
  final String attr;

  @override
  Object resolve(Context context) {
    Object value = expr.resolve(context);

    if (value == null || value is Undefined) {
      throw UndefinedError();
    }

    if (value is LoopContext) return value[attr];
    if (value is NameSpace) return value[attr];
    if (value is Map) return context.env.getItem(value, attr);
    return context.env.getField(value, attr);
  }

  @override
  String toDebugString([int level = 0]) => '${expr.toDebugString(level)}.$attr';

  @override
  String toString() => 'Field($expr, $attr)';
}

class Item extends Expression {
  Item(this.expr, this.item);

  final Expression expr;
  final Expression item;

  @override
  Object resolve(Context context) {
    Object value = expr.resolve(context);
    Object item = this.item.resolve(context);

    return context.env.getItem(value, item);
  }

  @override
  String toDebugString([int level = 0]) =>
      '${expr.toDebugString(level)}[${item.toDebugString()}]';

  @override
  String toString() => 'Item($expr, $item)';
}
