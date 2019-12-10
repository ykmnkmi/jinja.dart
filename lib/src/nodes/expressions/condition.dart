import '../core.dart';
import 'test.dart';

class Condition extends Expression {
  Condition(this.test, this.expr1, [this.expr2]);

  final Test test;
  final Expression expr1;
  final Expression expr2;

  @override
  dynamic resolve(Context context) {
    if (test.resolve(context)) return expr1.resolve(context);
    if (expr2 != null) return expr2.resolve(context);
    return null;
  }

  @override
  String toDebugString([int level = 0]) {
    var buffer = StringBuffer(' ' * level);

    if (expr2 != null) {
      buffer.write('${expr1.toDebugString()} ');
      buffer.write('if ${test.toDebugString()} or ${expr2.toDebugString()}');
    } else {
      buffer.write('${expr1.toDebugString()} if ${test.toDebugString()}');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    var buffer = StringBuffer('Condition($test, $expr1');
    if (expr2 != null) buffer.write(', $expr2');
    buffer.write(')');
    return buffer.toString();
  }
}
