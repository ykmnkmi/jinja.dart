import 'dart:io';

import 'package:jinja/jinja.dart';

void main() {
  final path = Platform.script.resolve('templates').toFilePath();

  final env = Environment(
    globals: <String, Object?>{
      'now': () {
        final dt = DateTime.now().toLocal();
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      },
    },
    autoReload: true,
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  print(env.getTemplate('users.html').render(
    users: [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ],
  ));
}
