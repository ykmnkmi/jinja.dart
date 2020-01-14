import '../../exceptions.dart';
import '../../runtime.dart';
import '../core.dart';

class Field extends Expression {
  Field(this.expr, this.attr);

  final Expression expr;
  final String attr;

  @override
  Object resolve(Context context) {
    final value = expr.resolve(context);

    if (value == null || value is Undefined) {
      // TODO: проверить: текст ошибки
      throw UndefinedError();
    }

    if (value is LoopContext) {
      return value[attr];
    }

    if (value is NameSpace) {
      return value[attr];
    }

    if (value is Map) {
      return context.environment.getItem(value, attr);
    }

    return context.environment.getField(value, attr);
  }

  @override
  String toDebugString([int level = 0]) {
    return '${expr.toDebugString(level)}.$attr';
  }

  @override
  String toString() {
    return 'Field($expr, $attr)';
  }
}

class Item extends Expression {
  Item(this.expr, this.item);

  final Expression expr;
  final Expression item;

  @override
  Object resolve(Context context) {
    final value = expr.resolve(context);
    final item = this.item.resolve(context);
    return context.environment.getItem(value, item);
  }

  @override
  String toDebugString([int level = 0]) {
    return '${expr.toDebugString(level)}[${item.toDebugString()}]';
  }

  @override
  String toString() {
    return 'Item($expr, $item)';
  }
}
