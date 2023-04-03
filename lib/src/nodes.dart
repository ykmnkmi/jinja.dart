import 'dart:math' as math;

import 'package:jinja/src/context.dart';
import 'package:jinja/src/namespace.dart';
import 'package:jinja/src/tests.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

typedef NodeVisitor = void Function(Node node);

abstract class Node {
  const Node();

  List<Node> get children {
    return const <Node>[];
  }

  R accept<C, R>(Visitor<C, R> visitor, C context);

  T find<T extends Node>() {
    var all = findAll<T>();
    return all.first;
  }

  Iterable<T> findAll<T extends Node>() sync* {
    for (var child in children) {
      if (child is T) {
        yield child;
      }

      yield* child.findAll<T>();
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
    return 'Data $literal';
  }
}
