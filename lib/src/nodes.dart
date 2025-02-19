import 'package:jinja/src/visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/statements.dart';

abstract base class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, C context);

  Node copyWith();

  Iterable<T> findAll<T extends Node>() sync* {}

  Map<String, Object?> toJson();
}

final class Data extends Node {
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
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Data',
      'data': data,
    };
  }
}

abstract base class Expression extends Node {
  const Expression();

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Expression',
    };
  }
}

abstract base class Statement extends Node {
  const Statement();
}

final class Slice extends Expression {
  const Slice({required this.value, required this.start, this.stop});

  final Expression value;

  final Expression? start;

  final Expression? stop;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSlice(this, context);
  }

  @override
  Slice copyWith({Expression? start, Expression? stop}) {
    return Slice(
      value: value,
      start: start ?? this.start,
      stop: stop ?? this.stop,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Slice',
      'start': start?.toJson(),
      'stop': stop?.toJson(),
      'value': value.toJson(),
    };
  }
}

final class Interpolation extends Node {
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
  Iterable<T> findAll<T extends Node>() sync* {
    if (value case T value) {
      yield value;
    }

    yield* value.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Interpolation',
      'value': value.toJson(),
    };
  }
}

final class Output extends Node {
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
  Iterable<T> findAll<T extends Node>() sync* {
    for (var node in nodes) {
      if (node is T) {
        yield node;
      }

      yield* node.findAll<T>();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'Output',
      'nodes': <Map<String, Object?>>[
        for (var node in nodes) node.toJson(),
      ],
    };
  }
}

final class TemplateNode extends Node {
  TemplateNode({
    this.blocks = const <Block>[],
    this.macros = const <Macro>[],
    required this.body,
  });

  final List<Block> blocks;

  final List<Macro> macros;

  final Node body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTemplateNode(this, context);
  }

  @override
  TemplateNode copyWith({
    List<Block>? blocks,
    List<Macro>? macros,
    Node? body,
  }) {
    return TemplateNode(
      blocks: blocks ?? this.blocks,
      macros: macros ?? this.macros,
      body: body ?? this.body,
    );
  }

  @override
  Iterable<T> findAll<T extends Node>() sync* {
    if (body case T body) {
      yield body;
    }

    yield* body.findAll<T>();
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': 'TemplateNode',
      'blocks': <Map<String, Object?>>[
        for (var block in blocks) block.toJson(),
      ],
      'macros': <Map<String, Object?>>[
        for (var macro in macros) macro.toJson(),
      ],
      'body': body.toJson(),
    };
  }
}
