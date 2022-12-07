import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';

void main() {
  var templatesUri = Platform.script.resolve('templates');

  var env = Environment(
    globals: <String, Object?>{
      'now': () {
        var dt = DateTime.now().toLocal();
        var hour = dt.hour.toString().padLeft(2, '0');
        var minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      },
    },
    autoReload: true,
    loader: FileSystemLoader(paths: <String>[templatesUri.path]),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  print(env.getTemplate('users.html').render({
    'users': [
      {'fullname': 'John Doe', 'email': 'johndoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ]
  }));
}

// ignore_for_file: avoid_print
