import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/utils.dart';

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
    path = formatPath(path);

    if (!hasSourceAccess) {
      throw UnsupportedError('this loader cannot provide access to the source');
    }

    throw TemplateNotFound(path: path);
  }

  /// Iterates over all templates.
  List<String> listTemplates() {
    throw UnsupportedError('this loader cannot iterate over all templates');
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
  MapLoader(Map<String, String> sources)
      : sources = sources.map<String, String>(
            (key, value) => MapEntry<String, String>(formatPath(key), value));

  final Map<String, String> sources;

  @override
  bool get hasSourceAccess {
    return false;
  }

  @override
  String getSource(String path) {
    path = formatPath(path);

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
    path = formatPath(path);

    var source = getSource(path);
    return environment.fromString(source, path: path);
  }
}
