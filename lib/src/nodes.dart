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

  List<Node> get childrens {
    return const <Node>[];
  }

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Iterable<T> findAll<T extends Node>() sync* {
    for (var child in childrens) {
      yield* child.findAll<T>();

      if (child is T) {
        yield child;
      }
    }
  }

  T findOne<T extends Node>() {
    var all = findAll<T>();
    return all.first;
  }

  void visitChildrens(NodeVisitor visitor) {
    childrens.forEach(visitor);
  }
}

class Output extends Node {
  Output(this.nodes);

  List<Node> nodes;

  @override
  List<Node> get childrens {
    return nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOutput(this, context);
  }

  @override
  String toString() {
    return 'Output(${nodes.join(', ')})';
  }

  static Node orSingle(List<Node> nodes) {
    switch (nodes.length) {
      case 0:
        return Data();
      case 1:
        return nodes[0];
      default:
        return Output(nodes);
    }
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

  void update(ExpressionUpdater updater) {}
}
