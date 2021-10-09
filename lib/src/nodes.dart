import 'dart:math' as math;

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

  Iterable<T> findAll<T extends Node>() {
    throw UnimplementedError();
  }

  void visitChildrens(NodeVisitor visitor) {}
}

extension on Node {
  void callBy(NodeVisitor visitor) {
    visitor(this);
  }
}

class Data extends Node {
  Data([this.data = '']);

  String data;

  bool get isLeaf {
    return trimmed.isEmpty;
  }

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
  void visitChildrens(NodeVisitor visitor) {}

  @override
  String toString() {
    return 'Data($literal)';
  }
}

class Impossible implements Exception {
  Impossible();
}

abstract class Expression extends Node {
  const Expression();

  Object? asConst(Context context) {
    throw Impossible();
  }

  Object? resolve(Context context) {
    return null;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExpession(this, context);
  }
}
