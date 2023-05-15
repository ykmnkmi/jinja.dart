import 'package:jinja/src/context.dart';
import 'package:jinja/src/namespace.dart';
import 'package:jinja/src/utils.dart';
import 'package:jinja/src/visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

typedef NodeVisitor = void Function(Node node);

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Node copyWith();
}

class Data extends Node {
  const Data([this.data = '']);

  final String data;

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
  Data copyWith({String? data}) {
    return Data(data ?? this.data);
  }

  @override
  String toString() {
    return 'Data $literal';
  }
}

class TemplateNode extends Node {
  TemplateNode({this.blocks = const <Block>[], required this.body});

  final List<Block> blocks;

  final List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplateNode(this, context);
  }

  @override
  TemplateNode copyWith({List<Block>? blocks, List<Node>? body}) {
    return TemplateNode(
      blocks: blocks ?? this.blocks,
      body: body ?? this.body,
    );
  }
}
