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

  factory Markup.from(Object? value) {
    return value is Markup ? value : Markup(value as String);
  }

  factory Markup.escaped(Object? value) {
    return value is Markup ? value : Escaped(value as String);
  }

  final String value;

  @override
  int get hashCode {
    return value.hashCode;
  }

  @override
  bool operator ==(Object? other) {
    return other is Markup && value == other.value;
  }

  @override
  String toString() {
    return escape(value);
  }
}

class Escaped implements Markup {
  Escaped(this.value);

  @override
  final String value;

  @override
  int get hashCode {
    return value.hashCode;
  }

  @override
  bool operator ==(Object? other) {
    return other is Markup && value == other.value;
  }

  @override
  String toString() {
    return value.toString();
  }
}
