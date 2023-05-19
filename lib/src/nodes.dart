import 'package:jinja/src/context.dart';
import 'package:jinja/src/visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Node copyWith();
}

class Data extends Node {
  const Data({this.data = ''});

  final String data;

  bool get isLeaf {
    return trimmed.isEmpty;
  }

  String get literal {
    return '"${data.replaceAll('"', r'\"').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}"';
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
    return Data(data: data ?? this.data);
  }

  @override
  String toString() {
    return 'Data $literal';
  }
}

abstract class Expression extends Node {
  const Expression();
}

class Callback extends Expression {
  const Callback({required this.callback});

  final Object? Function(Context context) callback;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCallback(this, context);
  }

  @override
  Callback copyWith({Object? Function(Context)? callback}) {
    return Callback(callback: callback ?? this.callback);
  }

  @override
  String toString() {
    return 'Callback';
  }
}

abstract class Statement extends Node {
  const Statement();
}

class Interpolation extends Node {
  const Interpolation({required this.value});

  final Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitInterpolation(this, context);
  }

  @override
  Interpolation copyWith({Expression? value}) {
    return Interpolation(value: value ?? this.value);
  }

  @override
  String toString() {
    return 'Interpolation $value';
  }
}

class Output extends Node {
  const Output({this.nodes = const <Node>[]});

  final List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOutput(this, context);
  }

  @override
  Output copyWith({List<Node>? nodes}) {
    return Output(nodes: nodes ?? this.nodes);
  }

  @override
  String toString() {
    return '{ ${nodes.join(', ')} }';
  }
}

class TemplateNode extends Node {
  const TemplateNode({this.blocks = const <Block>[], required this.body});

  final List<Block> blocks;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplateNode(this, context);
  }

  @override
  TemplateNode copyWith({List<Block>? blocks, Node? body}) {
    return TemplateNode(blocks: blocks ?? this.blocks, body: body ?? this.body);
  }

  @override
  String toString() {
    return 'TemplateNode $body';
  }
}
