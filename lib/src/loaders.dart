import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';

/// Base abstract class for all loaders.
/// Subclass this and override [getSource], [listTemplates] and [load]
/// to implement a custom loading mechanism.
abstract class Loader {
  bool get hasSourceAccess {
    return true;
  }

  /// Get template source from file.
  ///
  /// Throws [TemplateNotFound] if file not found
  /// or [UnsupportedError] if don't has access to source.
  String getSource(String path) {
    if (!hasSourceAccess) {
      throw UnsupportedError('This loader cannot provide access to the source');
    }

    throw TemplateNotFound(path: path);
  }

  /// Iterates over all templates.
  List<String> listTemplates() {
    throw UnsupportedError('This loader cannot iterate over all templates');
  }

  Template load(Environment environment, String path);
}

/// Loads a template from a map. It's passed a map of strings bound to
/// template names.
/// This loader is useful for testing.
///
///     var loader = MapLoader({'index.html': 'source here'})
///
class MapLoader extends Loader {
  MapLoader(this.sources);

  final Map<String, String> sources;

  @override
  bool get hasSourceAccess {
    return false;
  }

  @override
  String getSource(String path) {
    if (sources.containsKey(path)) {
      return sources[path]!;
    }

    throw TemplateNotFound(path: path);
  }

  @override
  List<String> listTemplates() {
    return sources.keys.toList();
  }

  @override
  Template load(Environment environment, String path) {
    var source = getSource(path);
    return environment.fromString(source, path: path);
  }
}
