class TemplateException implements Exception {}

class TemplateNotFound implements TemplateException {
  TemplateNotFound([this.message]);

  final String message;

  @override
  String toString() {
    if (message == null) return 'TemplateNotFound';
    return 'TemplateNotFound: $message';
  }
}

class TemplatesNotFound extends TemplateNotFound {
  TemplatesNotFound([String message]) : super(message);

  @override
  String toString() {
    if (message == null) return 'TemplatesNotFound';
    return 'TemplatesNotFound: $message';
  }
}
