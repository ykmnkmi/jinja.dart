import 'dart:math' as math;

import 'runtime.dart';
import 'tests.dart' as tests;
import 'utils.dart';
import 'visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

typedef NodeUpdater = Node Function(Node node);
typedef NodeVisitor = void Function(Node node);

abstract class ImportContext {
  bool get withContext;

  set withContext(bool withContext);
}

abstract class Node {
  const Node();

  List<Node> get childrens {
    return const <Node>[];
  }

  Iterable<T> findAll<T extends Node>() {
    return childrens.whereType<T>();
  }

  R accept<C, R>(Visitor<C, R> visitor, C context);

  T findOne<T extends Node>() {
    var all = findAll<T>();
    return all.first;
  }

  void update(NodeUpdater updater) {
    throw UnimplementedError(runtimeType.toString());
  }

  void visitChildrens(NodeVisitor visitor) {
    childrens.forEach(visitor);
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
  void update(Node Function(Node node) updater) {
    // TODO: remove
  }

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

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitExpession(this, context);
  }

  Object? asConst(Context context) {
    throw Impossible();
  }

  Object? resolve(Context context) {
    return null;
  }
}
