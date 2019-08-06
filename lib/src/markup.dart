Markup escape(value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (final ch in text.codeUnits) {
    switch (ch) {
      case 38:
        buffer.write('&amp;');
        break;
      case 34:
        buffer.write('&#34;');
        break;
      case 39:
        buffer.write('&#39;');
        break;
      case 60:
        buffer.write('&lt;');
        break;
      case 62:
        buffer.write('&gt;');
        break;
      default:
        buffer.writeCharCode(ch);
    }
  }
  return Markup(buffer.toString());
}

class Markup {
  const Markup(this.value);
  factory Markup.escape(String value) => escape(value);

  final String value;

  @override
  operator ==(other) => other is Markup && value == other.value;

  @override
  int get hashCode => super.hashCode ^ value.hashCode;

  @override
  String toString() => value;
}
