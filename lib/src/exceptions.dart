class TemplateError extends Error {
  TemplateError([this.message]);

  final Object? message;

  @override
  String toString() {
    if (message == null) {
      return 'TemplateError';
    }

    return 'TemplateError: $message';
  }
}

class TemplateNotFound extends TemplateError {
  TemplateNotFound([String? message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'TemplateNotFound';
    }

    return 'TemplateNotFound: $message';
  }
}

class TemplatesNotFound extends TemplateNotFound {
  TemplatesNotFound([String? message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'TemplatesNotFound';
    }

    return 'TemplatesNotFound: $message';
  }
}

class TemplateSyntaxError extends TemplateError {
  TemplateSyntaxError(String message, {this.path, this.line, this.column})
      : super(message);

  final Object? path;
  final int? line;
  final int? column;

  @override
  String toString() {
    final buffer = StringBuffer('TemplateSyntaxError');
    if (path != null) {
      buffer.write(' in \'$path\'');
    }

    if (line != null) {
      buffer.write(' on line ${line! + 1}');
      if (column != null) buffer.write(' column $column');
    }

    buffer.write(': $message');
    return buffer.toString();
  }
}

class TemplateRuntimeError extends TemplateError {
  TemplateRuntimeError([String? message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'TemplateRuntimeError';
    }

    return 'TemplateRuntimeError: $message';
  }
}

class UndefinedError extends TemplateRuntimeError {
  UndefinedError([String? message]) : super(message);

  @override
  String toString() {
    if (message == null) {
      return 'UndefinedError';
    }

    return 'UndefinedError: $message';
  }
}
