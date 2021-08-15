import 'environment.dart';
import 'exceptions.dart';

/// Base abstract class for all loaders.
/// Subclass this and override [getSource], [listTemplates] and [load]
/// to implement a custom loading mechanism.
abstract class Loader {
  /// Get template source from file.
  ///
  /// Throws [TemplateNotFound] if file not found
  /// or [UnsupportedError] if don't has access to source.
  String getSource(String template) {
    if (!hasSourceAccess) {
      throw UnsupportedError('this loader cannot provide access to the source');
    }

    throw TemplateNotFound(template: template);
  }

  bool get hasSourceAccess {
    return true;
  }

  @Deprecated('Use `listTemplates` instead. Will be removed in 0.5.0.')
  List<String> listSources() {
    return listTemplates();
  }

  /// Iterates over all templates.
  List<String> listTemplates() {
    throw UnsupportedError('this loader cannot iterate over all templates');
  }

  Template load(Environment environment, String template);
}

/// Loads a template from a map. It's passed a map of strings bound to
/// template names.
/// This loader is useful for testing:
///
///     var loader = MapLoader({'index.html': 'source here'})
///
class MapLoader extends Loader {
  MapLoader(this.mapping);

  final Map<String, String> mapping;

  @override
  bool get hasSourceAccess {
    return false;
  }

  @override
  String getSource(String template) {
    if (mapping.containsKey(template)) {
      return mapping[template]!;
    }

    throw TemplateNotFound(template: template);
  }

  @override
  List<String> listTemplates() {
    return mapping.keys.toList();
  }

  @override
  Template load(Environment environment, String template) {
    final source = getSource(template);
    return environment.fromString(source, path: template);
  }
}
