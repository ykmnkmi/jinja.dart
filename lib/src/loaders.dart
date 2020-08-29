import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'environment.dart';

/// Base abstract class for all loaders.
/// Subclass this and override [getSource], [listSources] and [load]
/// to implement a custom loading mechanism.
abstract class Loader {
  String getSource(String path) {
    throw Exception('template not found: $path');
  }

  bool get hasSourceAccess {
    return true;
  }

  /// Iterates over all templates.
  List<String> listSources() {
    throw Exception('this loader cannot iterate over all templates');
  }

  void load(Environment env) {
    for (final template in listSources()) {
      env.fromString(getSource(template), path: template);
    }
  }

  @override
  String toString() {
    return '$runtimeType';
  }
}

/// Loads templates from the file system.  This loader can find templates
/// in folders on the file system and is the preferred way to load them:
///
///     var loader = FileSystemLoader(path: 'templates', ext: ['html', 'xml']))
///     var loader = FileSystemLoader(paths: ['overrides/templates', 'default/templates'], ext: ['html', 'xml']))
///
/// Default values for path `templates` and file ext. `['html']`.
///
/// To follow symbolic links, set the [followLinks] parameter to `true`
///
///     var loader = FileSystemLoader(path: './path', followLinks: true)
///
class FileSystemLoader extends Loader {
  FileSystemLoader({
    String path = 'templates',
    List<String>? paths,
    this.followLinks = true,
    this.extensions = const <String>{'html'},
    this.encoding = utf8,
    this.autoReload = false,
  }) : paths = paths ?? <String>[path] {
    for (final path in this.paths) {
      if (!FileSystemEntity.isDirectorySync(path)) {
        // TODO: improve error message
        throw Exception('folder must be exist: $path');
      }
    }
  }

  final List<String> paths;
  final bool followLinks;
  final Set<String> extensions;
  final Encoding encoding;
  final bool autoReload;

  @deprecated
  Directory get directory => Directory(paths.last);

  @override
  String getSource(String template) {
    String? contents;

    for (final path in paths) {
      final templatePath = p.join(path, template);
      final templateFile = File(templatePath);

      if (templateFile.existsSync()) {
        contents = templateFile.readAsStringSync(encoding: encoding);
      }
    }

    if (contents == null) {
      // TODO: improve error message
      throw Exception('template not found: $template');
    }

    return contents;
  }

  @override
  List<String> listSources() {
    final found = <String>[];

    for (final path in paths) {
      final directory = Directory(path);

      if (directory.existsSync()) {
        final entities =
            directory.listSync(recursive: true, followLinks: followLinks);

        for (final entity in entities) {
          var template = p.relative(entity.path, from: path);
          var ext = p.extension(template);

          if (ext.isNotEmpty) {
            ext = ext.substring(1);
          }

          if (FileSystemEntity.typeSync(entity.path) ==
                  FileSystemEntityType.file &&
              extensions.contains(ext)) {
            template = template.replaceAll(p.separator, '/');

            if (!found.contains(template)) {
              found.add(template);
            }
          }
        }
      }
    }

    found.sort();
    return found;
  }

  @override
  void load(Environment env) {
    super.load(env);

    if (autoReload) {
      for (final path in paths) {
        Directory(path)
            .watch(recursive: true)
            .where((event) => event.type == FileSystemEvent.modify)
            .listen((event) {
          final template = p.relative(event.path, from: path);
          env.fromString(getSource(template), path: template);
        });
        ;
      }
    }
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
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
  MapLoader(this.dict) : hasSourceAccess = false;

  final Map<String, String> dict;

  @override
  final bool hasSourceAccess;

  @override
  List<String> listSources() {
    return dict.keys.toList();
  }

  @override
  String getSource(String path) {
    if (dict.containsKey(path)) {
      return dict[path]!;
    }

    throw Exception('template not found: $path');
  }

  @override
  String toString() {
    return 'MapLoader($dict)';
  }
}
