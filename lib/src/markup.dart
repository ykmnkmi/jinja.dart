String escape(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('>', '&gt;')
      .replaceAll('<', '&lt;')
      .replaceAll('\'', '&#39;')
      .replaceAll('"', '&#34;');
}

class Markup {
  const Markup(this.value);

  factory Markup.escape(String value) => Markup(escape(value));

  final String value;

  @override
  bool operator ==(Object other) => other is Markup && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
