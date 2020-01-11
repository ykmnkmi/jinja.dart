import 'core.dart';

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  void accept(StringSink outSink, Context context) {
    outSink.write(text);
  }

  @override
  String toDebugString([int level = 0]) {
    return ' ' * level + repr(text);
  }

  @override
  String toString() {
    return 'Text($text)';
  }
}
