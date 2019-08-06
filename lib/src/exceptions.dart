class FilterArgumantException implements Exception {
  const FilterArgumantException([this.message]);

  final String message;

  @override
  String toString() {
    if (message == null) return "FilterArgumantException";
    return "FilterArgumantException: $message";
  }
}
