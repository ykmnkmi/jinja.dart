import 'package:jinja/src/visitor.dart';

part '/src/nodes/expressions.dart';
part '/src/nodes/statements.dart';

abstract base class Node {
  const new();

  Iterable<Node> get childNodes {
    return Iterable<Node>.empty();
  }

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Node copyWith();

  T? find<T extends Node>() {
    for (var node in findAll<T>()) {
      return node;
    }

    return null;
  }

  Iterable<T> findAll<T extends Node>() sync* {
    for (var child in childNodes) {
      if (child is T) {
        yield child;
      }

      yield* child.findAll<T>();
    }
  }

  Map<String, Object?> toJson();
}

extension NodeListToJson on List<Node> {
  List<Map<String, Object?>> toJson() {
    return <Map<String, Object?>>[for (var node in this) node.toJson()];
  }
}

final class Data extends Node {
  const new({this.data = ''});

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
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Data', 'data': data};
  }
}

abstract base class Helper extends Node {
  const new();
}

abstract base class Expression extends Node {
  const new();

  bool get canAssign {
    return false;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Expression'};
  }
}

abstract base class Statement extends Node {
  const new();
}

final class Output extends Node {
  const new({this.nodes = const <Node>[]});

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOutput(this, context);
  }

  @override
  Output copyWith({List<Node>? nodes}) {
    return Output(nodes: nodes ?? this.nodes);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'Output', 'nodes': nodes.toJson()};
  }
}

final class TemplateNode extends Node {
  const new({required this.nodes});

  final List<Node> nodes;

  @override
  Iterable<Node> get childNodes sync* {
    yield* nodes;
  }

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplateNode(this, context);
  }

  @override
  TemplateNode copyWith({List<Node>? nodes}) {
    return TemplateNode(nodes: nodes ?? this.nodes);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'class': 'TemplateNode', 'nodes': nodes.toJson()};
  }
}
