import '../../exceptions.dart';
import '../core.dart';

class MoreEqual extends BinaryExpression {
  MoreEqual(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '>=';

  @override
  bool resolve(Context context) {
    var left = this.left.resolve(context);
    var right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) >= 0;
    }

    // TODO: MoreEqual exception message
    throw TemplateRuntimeError();
  }

  @override
  String toString() => 'MoreEqual($left, $right)';
}

class More extends BinaryExpression {
  More(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '>';

  @override
  bool resolve(Context context) {
    var left = this.left.resolve(context);
    var right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) > 0;
    }

    // TODO: More exception message
    throw TemplateRuntimeError();
  }

  @override
  String toString() => 'More($left, $right)';
}

class Less extends BinaryExpression {
  Less(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '<';

  @override
  bool resolve(Context context) {
    var left = this.left.resolve(context);
    var right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) < 0;
    }

    // TODO: Less exception message
    throw TemplateRuntimeError();
  }

  @override
  String toString() => 'Less($left, $right)';
}

class LessEqual extends BinaryExpression {
  LessEqual(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '<=';

  @override
  bool resolve(Context context) {
    var left = this.left.resolve(context);
    var right = this.right.resolve(context);

    if (left is Comparable && right is Comparable) {
      return left.compareTo(right) <= 0;
    }

    // TODO: LessEqual exception message
    throw TemplateRuntimeError();
  }

  @override
  String toString() => 'LessEqual($left, $right)';
}

class Equal extends BinaryExpression {
  Equal(this.left, this.right);

  @override
  final Expression left;

  @override
  final Expression right;

  @override
  String get symbol => '==';

  @override
  bool resolve(Context context) => left.resolve(context) == right.resolve(context);

  @override
  String toString() => 'Equal($left, $right)';
}
