part of '../nodes.dart';

abstract class Helper extends Node {
  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    throw UnimplementedError();
  }
}

class Pair extends Helper {
  Pair(this.key, this.value);

  Expression key;

  Expression value;

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}
