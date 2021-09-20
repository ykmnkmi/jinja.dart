import 'dart:math' as math;

import 'exceptions.dart';
import 'runtime.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

typedef NodeVisitor = void Function(Node node);

abstract class ImportContext {
  bool get withContext;

  set withContext(bool withContext);
}

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Iterable<T> listExpressions<T extends Expression>();

  Iterable<Node> listChildrens({bool deep = false});
}

class Data extends Node {
  Data([this.data = '']);

  String data;

  String get literal {
    return "'${data.replaceAll("'", r"\'").replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}'";
  }

  String get trimmed {
    return data.trim();
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitData(this, context);
  }

  @override
  Iterable<Node> listChildrens({bool deep = false}) sync* {}

  @override
  Iterable<T> listExpressions<T extends Expression>() sync* {}

  @override
  String toString() {
    return 'Data()';
  }
}
