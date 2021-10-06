import 'dart:convert' show Encoding;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
      : paths = paths ?? <String>[path ?? 'templates'];

  final List<String> paths;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  File? findFile(String template) {
    var pieces = template.split('/');

    for (var path in paths) {
      var templatePath = p.joinAll(<String>[path, ...pieces]);
      var templateFile = File(templatePath);

      if (templateFile.existsSync()) {
        return templateFile;
      }
    }
  }

  bool isTemplate(String path, [String? from]) {
    var template = p.relative(path, from: from);
    var ext = p.extension(template);

    if (ext.startsWith('.')) {
      ext = ext.substring(1);
    }

    return extensions.contains(ext) &&
        FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
  }

  @override
  String getSource(String template) {
    var file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @override
  List<String> listTemplates() {
    var found = <String>[];

    for (var path in paths) {
      var directory = Directory(path);

      if (directory.existsSync()) {
        var entities =
            directory.listSync(recursive: true, followLinks: followLinks);

        for (var entity in entities) {
          if (isTemplate(entity.path, path)) {
            var template = p
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
    var file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    var source = file.readAsStringSync(encoding: encoding);
    return environment.fromString(source, path: template);
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
}
