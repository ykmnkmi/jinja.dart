import 'utils.dart';

class Markup {
  const factory Markup.escaped(Object? value) = Escaped;

  factory Markup(Object? value) {
    if (value is Markup) {
      return value;
    }

    return Markup.escape(value);
  }

  Markup.escape(this.value);

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
