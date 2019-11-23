import 'core.dart';
import 'text.dart';

class Interpolation extends Statement {
  static Node orNode(List<Node> nodes) {
    if (nodes.isEmpty) return Text('');
    if (nodes.length == 1) return nodes.first;
    return Interpolation(nodes);
  }

  Interpolation(this.nodes);

  final List<Node> nodes;

  @override
  void accept(StringBuffer buffer, Context context) {
    for (Node node in nodes) {
      node.accept(buffer, context);
    }
  }

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer(' ' * level);
    buffer.writeln('# interpolation');
    buffer.writeAll(nodes.map<String>((Node node) => node.toDebugString(level + 1)), '\n');
    return '$buffer';
  }

  @override
  String toString() => 'Interpolation($nodes)';
}
