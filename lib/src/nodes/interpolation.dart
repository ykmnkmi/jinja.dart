import 'core.dart';

class Interpolation extends Statement {
  static Node orNode(List<Node> nodes) {
    // TODO: update exception
    if (nodes.isEmpty) throw Exception('nodes empty');
    if (nodes.length == 1) return nodes.first;
    return Interpolation(nodes);
  }

  Interpolation(this.nodes);

  @override
  final List<Node> nodes;

  @override
  void accept(StringBuffer buffer, Context context) {
    for (var node in nodes) {
      node.accept(buffer, context);
    }
  }

  @override
  String toDebugString([int level = 0]) =>
      nodes.map((node) => node.toDebugString(level)).join('\n');

  @override
  String toString() => 'Interpolation($nodes)';
}
