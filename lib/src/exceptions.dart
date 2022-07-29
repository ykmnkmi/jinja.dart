/// Baseclass for all template errors.
abstract class TemplateError implements Exception {
  const TemplateError([this.message]);

  final String? message;

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
  const TemplateNotFound({String? path, String? message})
      : super(message ?? path);
}

/// Like [TemplateNotFound] but raised if multiple templates are selected.
class TemplatesNotFound extends TemplateNotFound {
  TemplatesNotFound({List<Object?>? names, super.message});
}

/// Raised to tell the user that there is a problem with the template.
class TemplateSyntaxError extends TemplateError {
  const TemplateSyntaxError(super.message, {this.path, this.line});

  final String? path;

  final int? line;

  @override
  String toString() {
    var result = runtimeType.toString();

    if (path != null) {
      if (result.contains(',')) {
        result += ', file: $path';
      }

      result += ' file: $path';
    }

    if (line != null) {
      if (result.contains(',')) {
        result += ', line: $line';
      } else {
        result += ' line: $line';
      }
    }

    if (message == null) {
      return result;
    }

    return '$result: $message';
  }
}

/// Like a template syntax error, but covers cases where something in the
/// template caused an error at compile time that wasn't necessarily caused
/// by a syntax error.
///
/// However it's a direct subclass of [TemplateSyntaxError] and has the same
/// attributes.
class TemplateAssertionError extends TemplateError {
  const TemplateAssertionError([super.message]);
}

/// A generic runtime error in the template engine.
///
/// Under some situations Jinja may raise this exception.
class TemplateRuntimeError extends TemplateError {
  const TemplateRuntimeError([super.message]);
}

/// This error is raised if a filter was called with inappropriate arguments.
class FilterArgumentError extends TemplateRuntimeError {
  const FilterArgumentError([super.message]);
}
