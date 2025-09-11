library jinja.loaders;

import 'dart:convert';
import 'dart:io';

import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/loaders.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' show extension, join, normalize, relative;

export 'package:jinja/src/loaders.dart';

/// {@template jinja.FileSystemLoader}
/// Loads templates from the file system.
///
/// This loader can find templates in folders on the file system and is the
/// preferred way to load them:
/// ```dart
/// var loader = FileSystemLoader(
///   path: 'templates',
///   extensions: ['html', 'xml'],
/// );
/// ```
/// or:
/// ```dart
/// var loader = FileSystemLoader(
///   paths: ['overrides/templates', 'default/templates'],
///   extensions: ['html', 'xml'],
/// );
/// ```
/// To follow symbolic links, set the [followLinks] parameter to `true`:
/// ```dart
/// var loader = FileSystemLoader(path: 'path', followLinks: true);
/// ```
/// {@endtemplate}
class FileSystemLoader extends Loader {
  /// {@macro jinja.FileSystemLoader}
  FileSystemLoader({
    List<String> paths = const <String>['templates'],
    this.recursive = true,
    this.followLinks = true,
    this.extensions = const <String>{'html'},
    this.encoding = utf8,
  }) : paths = paths.map<String>(normalize).toList();

  final List<String> paths;

  final bool recursive;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  @protected
  File? findFile(String path) {
    for (var root in paths) {
      var file = File(join(root, path));

      if (file.existsSync()) {
        return file;
      }
    }

    return null;
  }

  @override
  String getSource(String path) {
    var file = findFile(path);

    if (file == null) {
      throw TemplateNotFound(name: path);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @protected
  bool isTemplate(String template) {
    var templateExtention = extension(template);

    if (templateExtention.startsWith('.')) {
      templateExtention = templateExtention.substring(1);
    }

    return extensions.contains(templateExtention) &&
        FileSystemEntity.isFileSync(template);
  }

  @override
  List<String> listTemplates() {
    var found = <String>{};

    for (var root in paths) {
      var directory = Directory.fromUri(Uri.directory(root));

      if (directory.existsSync()) {
        var entities = directory.listSync(
          recursive: recursive,
          followLinks: followLinks,
        );

        for (var entity in entities) {
          if (isTemplate(entity.path)) {
            var uri = Uri.file(relative(entity.path, from: root));
            found.add(uri.path);
          }
        }
      }
    }

    return found.toList()..sort();
  }

  @override
  Template load(
    Environment environment,
    String path, {
    Map<String, Object?>? globals,
  }) {
    return environment.fromString(
      getSource(path),
      path: path,
      globals: globals,
    );
  }
}
