import 'core.dart';

class Text extends Node {
  Text(this.text);

  final String text;

  @override
  void accept(StringBuffer buffer, Context context) {
    buffer.write(text);
  }

  @override
  String toDebugString([int level = 0]) => ' ' * level + repr(text);

  @override
  String toString() => 'Text($text)';
}
