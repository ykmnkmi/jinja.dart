library jinja.loaders;

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' show extension, join, normalize, relative;

import 'src/environment.dart';
import 'src/exceptions.dart';
import 'src/loaders.dart';

export 'src/loaders.dart';

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
  FileSystemLoader(
      {String? path,
      List<String>? paths,
      this.followLinks = true,
      this.extensions = const <String>{'html'},
      this.encoding = utf8})
      : paths = paths == null
            ? <String>[path == null ? 'templates' : normalize(path)]
            : paths.map<String>(normalize).toList();

  final List<String> paths;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  @protected
  File? findFile(String path) {
    path = normalize(path);

    for (var root in paths) {
      var file = File(join(root, path));

      if (file.existsSync()) {
        return file;
      }
    }

    return null;
  }

  @protected
  bool isTemplate(String path, [String? from]) {
    var template = relative(path, from: from);
    var templateExtension = extension(template);

    if (templateExtension.startsWith('.')) {
      templateExtension = templateExtension.substring(1);
    }

    return extensions.contains(templateExtension) &&
        FileSystemEntity.isFileSync(path);
  }

  @override
  String getSource(String path) {
    var file = findFile(path);

    if (file == null) {
      throw TemplateNotFound(path: path);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @override
  List<String> listTemplates() {
    var found = <String>{};

    for (var path in paths) {
      var directory = Directory(path);

      if (directory.existsSync()) {
        var entities =
            directory.listSync(recursive: true, followLinks: followLinks);

        for (var entity in entities) {
          if (isTemplate(entity.path, path)) {
            var template = relative(entity.path, from: path)
                .replaceAll(Platform.pathSeparator, '/');
            found.add(template);
          }
        }
      }
    }

    var list = found.toList();
    list.sort();
    return list;
  }

  @override
  Template load(Environment environment, String path) {
    var file = findFile(path);

    if (file == null) {
      throw TemplateNotFound(path: path);
    }

    var source = file.readAsStringSync(encoding: encoding);
    return environment.fromString(source, path: path);
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
}
