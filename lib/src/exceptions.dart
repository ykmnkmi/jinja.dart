/// Base class for all template errors.
abstract class TemplateError implements Exception {
  /// Creates a new [TemplateError].
  TemplateError([this.message]);

  /// The error message.
  final String? message;

  @override
  String toString() {
    if (message != null) {
      return 'TemplateError: $message';
    }

    return 'TemplateError';
  }
}

/// Thrown if a template does not exist.
class TemplateNotFound extends TemplateError {
  /// Creates a new [TemplateNotFound].
  TemplateNotFound({String? message, this.name}) : super(message);

  /// The name of the template that was not found.
  final String? name;

  @override
  String toString() {
    if (message != null) {
      return 'TemplateNotFound: $message';
    }

    if (name != null) {
      return 'TemplateNotFound: $name';
    }

    return 'TemplateNotFound';
  }
}

/// Like [TemplateNotFound], but thrown if multiple templates are selected.
class TemplatesNotFound extends TemplateNotFound {
  /// Creates a new [TemplatesNotFound].
  TemplatesNotFound({super.message, this.names}) : super(name: names?.last);

  /// The names of the templates that were not found.
  final List<String>? names;

  @override
  String toString() {
    if (message != null) {
      return 'TemplatesNotFound: $message';
    }

    if (names != null) {
      return 'TemplatesNotFound: none of the templates given were found: '
          '${names!.join(', ')}';
    }

    return 'TemplatesNotFound: $message';
  }
}

/// Thrown to tell the user that there is a problem with the template.
class TemplateSyntaxError extends TemplateError {
  /// Creates a new [TemplateSyntaxError].
  TemplateSyntaxError(super.message, {this.name, this.path, this.line});

  /// The name of the template that caused the error.
  final String? name;

  /// The path to the template that caused the error.
  final String? path;

  /// The line in the template that caused the error.
  final int? line;

  String _toString(String type) {
    var buffer = StringBuffer(type);

    if (path != null) {
      buffer.write(" path '$path'");
    }
    if (name != null) {
      buffer.write(" name '$name'");
    }

    if (line != null) {
      buffer.write(" line '$line'");
    }

    if (message != null) {
      buffer.write(': $message');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return _toString('TemplateSyntaxError');
  }
}

/// Like a [TemplateSyntaxError], but covers cases where something in the
/// template caused an error at parsing time that wasn't necessarily caused
/// by a syntax error.
class TemplateAssertionError extends TemplateSyntaxError {
  /// Creates a new [TemplateAssertionError].
  TemplateAssertionError(super.message, {super.name, super.path, super.line});

  @override
  String toString() {
    return _toString('TemplateAssertionError');
  }
}

/// A generic runtime error in the template engine.
///
/// Under some situations Jinja may throw this exception.
class TemplateRuntimeError extends TemplateError {
  /// Creates a new [TemplateRuntimeError].
  TemplateRuntimeError([super.message]);

  @override
  String toString() {
    if (message != null) {
      return 'TemplateRuntimeError: $message';
    }

    return 'TemplateRuntimeError';
  }
}

/// Thrown if a variable is undefined.
class UndefinedError extends TemplateRuntimeError {
  /// Creates a new [UndefinedError].
  UndefinedError([super.message]);

  @override
  String toString() {
    if (message != null) {
      return 'UndefinedError: $message';
    }

    return 'UndefinedError';
  }
}
