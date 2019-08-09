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
  bool resolve(Context context) =>
      // ignore: return_of_invalid_type
      left.resolve(context) >= right.resolve(context);

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
  bool resolve(Context context) =>
      (left.resolve(context) > right.resolve(context)) as bool;

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
  bool resolve(Context context) =>
      // ignore: return_of_invalid_type
      left.resolve(context) < right.resolve(context);

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
  bool resolve(Context context) =>
      // ignore: return_of_invalid_type
      left.resolve(context) <= right.resolve(context);

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
  bool resolve(Context context) =>
      left.resolve(context) == right.resolve(context);

  @override
  String toString() => 'Equal($left, $right)';
}
