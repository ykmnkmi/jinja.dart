// ignore_for_file: always_specify_types

import 'dart:io';

import 'package:jinja/jinja.dart';

void main() {
  String path = Platform.script.resolve('.').toFilePath();

  Environment env = Environment(
    globals: {
      'now': () {
        DateTime dt = DateTime.now().toLocal();
        String hour = dt.hour < 10 ? '0${dt.hour}' : dt.hour.toString();
        String minute = dt.minute < 10 ? '0${dt.minute}' : dt.minute.toString();
        return '$hour:$minute';
      },
    },
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  Template template = env.getTemplate('users.html');
  stdout.write(template.renderWr(users: [
    {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
    {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
  ]));
}
