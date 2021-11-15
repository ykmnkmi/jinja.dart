import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';

void main() {
  var path = Directory.current.uri.resolve('example/templates').toFilePath();

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
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  print(env.getTemplate('users.html').render({
    'users': [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ]
  }));
}
