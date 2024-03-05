import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';

/// {@template jinja.Loader}
/// Base abstract class for all loaders.
///
/// Subclass this and override [getSource], [listTemplates] and [load]
/// to implement a custom loading mechanism.
/// {@endtemplate}
abstract class Loader {
  /// {@macro jinja.Loader}
  const Loader();

  /// Returns `true` if this loader can provide access to the source.
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

    throw TemplateNotFound(name: path);
  }

  /// Iterates over all templates.
  List<String> listTemplates() {
    throw UnsupportedError('This loader cannot iterate over all templates');
  }

  /// Loads a template to the environment template cache.
  Template load(
    Environment environment,
    String path, {
    Map<String, Object?>? globals,
  });
}

/// {@template jinja.MapLoader}
/// Loads a template from a map.
///
/// It's passed a map of strings bound to template names. This loader is
/// useful for testing.
///
///     var loader = MapLoader({'index.html': 'source here'})
///
/// {@endtemplate}
class MapLoader extends Loader {
  /// {@macro jinja.MapLoader}
  // TODO(loaders): comment that the map keys should be URI paths,
  // like 'path/to/template.html'
  const MapLoader(this.sources);

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

    throw TemplateNotFound(name: path);
  }

  @override
  List<String> listTemplates() {
    return sources.keys.toList();
  }

  @override
  Template load(
    Environment environment,
    String path, {
    Map<String, Object?>? globals,
  }) {
    var source = getSource(path);
    return environment.fromString(source, path: path, globals: globals);
  }
}
