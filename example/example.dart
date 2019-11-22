// ignore_for_file: always_specify_types

import 'package:jinja/jinja.dart';

void main() {
  Environment env = Environment(
    globals: <String, Object>{
      'now': () {
        DateTime dt = DateTime.now().toLocal();
        String hour = dt.hour < 10 ? '0${dt.hour}' : dt.hour.toString();
        String minute = dt.minute < 10 ? '0${dt.minute}' : dt.minute.toString();
        return '$hour:$minute';
      },
    },
    loader: FileSystemLoader(path: 'example'),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  Template template = env.getTemplate('users.html');

  print(template.render(
    users: [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ],
  ));
}
