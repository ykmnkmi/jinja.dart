import 'dart:io';

import 'package:jinja/jinja.dart';

void main() {
  final String path = Platform.script.resolve('.').toFilePath();

  final Environment env = Environment(
    globals: <String, Object>{
      'now': () {
        final DateTime dt = DateTime.now().toLocal();
        final String hour = dt.hour < 10 ? '0${dt.hour}' : dt.hour.toString();
        final String minute =
            dt.minute < 10 ? '0${dt.minute}' : dt.minute.toString();
        return '$hour:$minute';
      },
    },
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  final Template template = env.getTemplate('users.html');

  stdout.write(template.render(users: [
    {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
    {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
  ]));
}
