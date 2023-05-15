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
}

class Output extends Node {
  const Output({this.body = const <Node>[]});

  final List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOutput(this, context);
  }

  @override
  Output copyWith({List<Node>? body}) {
    return Output(body: body ?? this.body);
  }
}
