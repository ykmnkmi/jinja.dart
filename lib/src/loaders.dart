import 'dart:io';

import 'package:path/path.dart' as _path;

import 'environment.dart';

/// Base abstract class for all loaders.
/// Subclass this and override [getSource], [listSources] and [load]
/// to implement a custom loading mechanism.
abstract class Loader {
  /// Get the template source.
  String getSource(String path) {
    throw Exception('Template not found: $path');
  }

  /// If set to `false` it indicates that the loader cannot provide access
  /// to the source of templates.
  bool get hasSourceAccess => true;

  /// Iterates over all templates.
  List<String> listSources() {
    throw Exception('This loader cannot iterate over all templates');
  }

  /// Loads a template to environment cache.
  void load(Environment environment) {
    for (var path in listSources()) {
      environment.fromSource(getSource(path), path: path);
    }
  }

  @override
  String toString() => 'Loader()';
}

/// Loads templates from the file system.  This loader can find templates
/// in folders on the file system and is the preferred way to load them:
///
///     var loader = FileSystemLoader(path: '/path/to/folder', ext: ['html', 'xml']))
///
/// Default value path `/templates` and file ext. `['html']`.
///
/// To follow symbolic links, set the [followLinks] parameter to `true`
///
///     var loader = FileSystemLoader(path: '/path', followLinks: true)
///
class FileSystemLoader extends Loader {
  FileSystemLoader({
    this.autoReload = false,
    this.extensions = const <String>['html'],
    String path = '/templates',
    this.followLinks = true,
  }) : directory = Directory(path) {
    if (!directory.existsSync())
      throw ArgumentError.value(path, 'path', 'Wrong path');
  }

  final bool autoReload;
  final List<String> extensions;
  final Directory directory;
  final bool followLinks;

  @override
  String getSource(String path) {
    final templatePath = _path.join(directory.path, path);
    final templateFile = File(templatePath);

    if (!templateFile.existsSync()) {
      throw Exception('Template not found: $path');
    }

    return templateFile.readAsStringSync();
  }

  @override
  List<String> listSources() => directory
      .listSync(recursive: true, followLinks: followLinks)
      .map<String>(
          (entity) => _path.relative(entity.path, from: directory.path))
      .where((path) => extensions.contains(_path.extension(path).substring(1)))
      .toList();

  @override
  void load(Environment env) {
    super.load(env);
    if (autoReload) {
      directory
          .watch(recursive: true)
          .where((event) => event.type == FileSystemEvent.modify)
          .listen((event) {
        final path = _path.relative(event.path, from: directory.path);
        env.fromSource(getSource(path), path: path);
      });
    }
  }

  @override
  String toString() => 'FileSystemLoader($directory)';
}

/// Loads a template from a map. It's passed a map of strings bound to
/// template names.
/// This loader is useful for testing:
///
///     var loader = MapLoader({'index.html': 'source here'})
///
/// Because auto reloading is rarely useful this is disabled per default.
///
class MapLoader extends Loader {
  MapLoader(this.dict);

  final Map<String, String> dict;

  @override
  final bool hasSourceAccess = false;

  @override
  List<String> listSources() => dict.keys.toList();

  @override
  String getSource(String path) {
    if (dict.containsKey(path)) return dict[path];
    throw Exception('Template not found: $path');
  }

  @override
  String toString() => 'MapLoader($dict)';
}
