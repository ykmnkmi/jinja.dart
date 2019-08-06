import 'dart:io';

import 'package:path/path.dart' as _path;

import 'env.dart';

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

  /// Loads a template to env cache.
  void load(Environment env) {
    for (final path in listSources())
      env.fromSource(getSource(path), path: path, store: true);
  }

  @override
  String toString() => 'Loader()';
}

/// Loads templates from the file system.  This loader can find templates
/// in folders on the file system and is the preferred way to load them:
///
///     var loader = FileSystemLoader(path: '/path', ext: ['html', 'xml']))
///
/// Default value path `lib/src/templates` and file ext. `['html']`.
///
/// To follow symbolic links, set the [followLinks] parameter to `true`
///
///     var loader = FileSystemLoader(path: '/path', followLinks: true)
///
class FileSystemLoader extends Loader {
  FileSystemLoader(
      {this.ext = const ['html'],
      String path = 'lib/src/templates',
      this.followLinks = true})
      : dir = Directory(path) {
    if (!dir.existsSync())
      throw ArgumentError.value(path, 'path', 'Wrong path');
  }

  final List<String> ext;
  final Directory dir;
  final bool followLinks;

  @override
  String getSource(String path) =>
      File(_path.join(dir.path, path)).readAsStringSync();

  @override
  List<String> listSources() => dir
      .listSync(recursive: true, followLinks: followLinks)
      .map<String>((entity) => _path.relative(entity.path, from: dir.path))
      .where((path) => ext.contains(_path.extension(path).substring(1)))
      .toList();

  @override
  void load(Environment env) {
    super.load(env);
    if (env.autoReload) {
      dir
          .watch(recursive: true)
          .where((event) => event.type == FileSystemEvent.modify)
          .listen((event) {
        final path = _path.relative(event.path, from: dir.path);
        env.fromSource(getSource(path), path: path, store: true);
      });
    }
  }

  @override
  String toString() => 'FileSystemLoader($dir)';
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
    throw ArgumentError.value(path, 'path', 'Template not found');
  }

  @override
  String toString() {
    final keys = dict.keys.map((key) => '\'$key\'').join(', ');
    return 'MapLoader($keys)';
  }
}
