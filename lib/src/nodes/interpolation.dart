import 'core.dart';

class Interpolation extends Statement {
  Interpolation(this.nodes);

  final List<Node> nodes;

  @override
  void accept(StringBuffer buffer, Context context) {
    nodes.forEach((node) {
      node.accept(buffer, context);
    });
  }

  @override
  String toDebugString([int level = 0]) =>
      nodes.map((node) => node.toDebugString(level)).join('\n');

  @override
  String toString() => 'Interpolation($nodes)';
}
