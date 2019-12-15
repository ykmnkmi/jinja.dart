import 'core.dart';

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  void accept(StringSink outSink, Context context) {
    outSink.write(text);
  }

  @override
  String toDebugString([int level = 0]) => ' ' * level + repr(text);

  @override
  String toString() => 'Text($text)';
}
