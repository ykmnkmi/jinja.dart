class TemplateError extends Error {
  TemplateError([this.message]);

  final String message;

  @override
  String toString() {
    if (message == null) return 'TemplateError';
    return 'TemplateError: $message';
  }
}

class TemplateNotFound extends TemplateError {
  TemplateNotFound([String message]) : super(message);

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

class TemplateSyntaxError extends TemplateError {
  TemplateSyntaxError(String message, this.path, this.line, this.position)
      : super(message);

  final String path;
  final int line;
  final int position;

  @override
  String toString() => 'TemplateSyntaxError in \'$path\''
      ' on line $line, column $position : $message';
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([String message]) : super(message);

  @override
  String toString() {
    if (message == null) return 'TemplateRuntimeError';
    return 'TemplateRuntimeError: $message';
  }
}

class UndefinedError extends TemplateRuntimeError {
  UndefinedError([String message]) : super(message);

  @override
  String toString() {
    if (message == null) return 'UndefinedError';
    return 'UndefinedError: $message';
  }
}
