class Markup {
  factory Markup(Object? value) {
    if (value is Markup) {
      return value;
    }

    return Markup.escape(value);
  }

  Markup.escape(this.value);

  const factory Markup.escaped(Object? value) = Escaped;

  final Object? value;

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
    return escape(value.toString());
  }
}

class Escaped implements Markup {
  const Escaped(this.value);

  @override
  final Object? value;

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

String escape(Object? object) {
  var string = object.toString();
  var start = 0;
  StringBuffer? result;

  for (var i = 0; i < string.length; i++) {
    String? replacement;

    switch (string[i]) {
      case '&':
        replacement = '&amp;';
        break;
      case '"':
        replacement = '&#34;';
        break;
      case "'":
        replacement = '&#39;';
        break;
      case '<':
        replacement = '&lt;';
        break;
      case '>':
        replacement = '&gt;';
        break;
    }

    if (replacement != null) {
      result ??= StringBuffer();
      result.write(string.substring(start, i));
      result.write(replacement);
      start = i + 1;
    }
  }

  if (result == null) {
    return string;
  }

  result.write(string.substring(start));
  return result.toString();
}

String escapeSafe(Object? object) {
  if (object is Markup) {
    return object.value.toString();
  }

  return escape(object);
}
