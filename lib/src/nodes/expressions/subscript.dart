import '../../exceptions.dart';
import '../../undefined.dart';
import '../core.dart';

class Field extends Expression {
  Field(this.attr, this.expr);

  final String attr;
  final Expression expr;

  @override
  dynamic resolve(Context context) {
    final value = expr.resolve(context);

    if (value == null || value is Undefined) {
      throw UndefinedError();
    }

    // TODO: ?? env.undefined
    return tryGetField(value, attr);
  }

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
  dynamic resolve(Context context) {
    final value = expr.resolve(context);
    final item = this.item.resolve(context);

    // TODO: ?? env.undefined
    return tryGetItem(value, item);
  }

  @override
  String toDebugString([int level = 0]) =>
      '${expr.toDebugString(level)}[${item.toDebugString()}]';

  @override
  String toString() => 'Item($item, $expr)';
}
