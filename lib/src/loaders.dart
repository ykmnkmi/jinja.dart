import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
///     var loader = FileSystemLoader(path: 'path', followLinks: true)
///
class FileSystemLoader extends Loader {
  FileSystemLoader({
    String? path,
    List<String>? paths,
    this.followLinks = true,
    this.extensions = const <String>{'html'},
    this.encoding = utf8,
  }) : paths = paths ?? <String>[path ?? 'templates'];

  final List<String> paths;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  File? findFile(String template) {
    final pieces = template.split('/');

    for (final path in paths) {
      final templatePath = p.joinAll(<String>[path, ...pieces]);
      final templateFile = File(templatePath);

      if (templateFile.existsSync()) {
        return templateFile;
      }
    }
  }

  bool isTemplate(String path, [String? from]) {
    final template = p.relative(path, from: from);
    var ext = p.extension(template);

    if (ext.startsWith('.')) {
      ext = ext.substring(1);
    }

    return extensions.contains(ext) &&
        FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
  }

  @override
  String getSource(String template) {
    final file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @override
  List<String> listTemplates() {
    final found = <String>[];

    for (final path in paths) {
      final directory = Directory(path);

      if (directory.existsSync()) {
        final entities =
            directory.listSync(recursive: true, followLinks: followLinks);

        for (final entity in entities) {
          if (isTemplate(entity.path, path)) {
            final template = p
                .relative(entity.path, from: path)
                .replaceAll(Platform.pathSeparator, '/');

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
  Template load(Environment environment, String template) {
    final file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    final source = file.readAsStringSync(encoding: encoding);
    return environment.fromString(source, path: template);
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
}
