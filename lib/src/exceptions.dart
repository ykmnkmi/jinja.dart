/// Baseclass for all template errors.
abstract class TemplateError implements Exception {
  const TemplateError([this.message]);

  final Object? message;

  @override
  String toString() {
    if (message == null) {
      return '$runtimeType';
    }

    return '$runtimeType: $message';
  }
}

/// Raised if a template does not exist.
class TemplateNotFound extends TemplateError {
  const TemplateNotFound({Object? template, Object? message})
      : super(message ?? template);
}

/// Like [TemplateNotFound] but raised if multiple templates are selected.
class TemplatesNotFound extends TemplateNotFound {
  TemplatesNotFound({List<Object?>? names, Object? message})
      : super(message: message);
}

/// Raised to tell the user that there is a problem with the template.
class TemplateSyntaxError extends TemplateError {
  const TemplateSyntaxError(String message, {this.line, this.path})
      : super(message);

  final int? line;

  final String? path;

  @override
  String toString() {
    var prefix = 'TemplateSyntaxError';

    if (path != null) {
      if (prefix.contains(',')) {
        prefix += ', file: $path';
      }

      prefix += ' file: $path';
    }

    if (line != null) {
      if (prefix.contains(',')) {
        prefix += ', line: $line';
      } else {
        prefix += ' line: $line';
      }
    }

    return '$prefix: $message';
  }
}

/// A generic runtime error in the template engine.
///
/// Under some situations Jinja may raise this exception.
class TemplateRuntimeError extends TemplateError {
  const TemplateRuntimeError([Object? message]) : super(message);
}

/// This error is raised if a filter was called with inappropriate arguments.
class FilterArgumentError extends TemplateRuntimeError {
  const FilterArgumentError([Object? message]) : super(message);
}
