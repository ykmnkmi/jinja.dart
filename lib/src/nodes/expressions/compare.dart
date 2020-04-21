import '../../exceptions.dart';
import '../core.dart';

class MoreEqual extends BinaryExpression {
  MoreEqual(this.left, this.right) : symbol = '>=';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) >= 0;
    }

    // TODO: добавить: текст ошибки = add: error message
    throw TemplateRuntimeError();
  }

  @override
  String toString() {
    return 'MoreEqual($left, $right)';
  }
}

class More extends BinaryExpression {
  More(this.left, this.right) : symbol = '>';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) > 0;
    }

    // TODO: добавить: текст ошибки = add: error message
    throw TemplateRuntimeError();
  }

  @override
  String toString() {
    return 'More($left, $right)';
  }
}

class Less extends BinaryExpression {
  Less(this.left, this.right) : symbol = '<';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) < 0;
    }

    // TODO: добавить: текст ошибки = add: error message
    throw TemplateRuntimeError();
  }

  @override
  String toString() {
    return 'Less($left, $right)';
  }
}

class LessEqual extends BinaryExpression {
  LessEqual(this.left, this.right) : symbol = '<=';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    final left = this.left.resolve(context);
    final right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) <= 0;
    }

    // TODO: добавить: текст ошибки = add: error message
    throw TemplateRuntimeError();
  }

  @override
  String toString() {
    return 'LessEqual($left, $right)';
  }
}

class Equal extends BinaryExpression {
  Equal(this.left, this.right) : symbol = '==';

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  final String symbol;

  @override
  bool resolve(Context context) {
    return left.resolve(context) == right.resolve(context);
  }

  @override
  String toString() {
    return 'Equal($left, $right)';
  }
}
