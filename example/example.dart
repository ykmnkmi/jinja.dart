import 'package:jinja/jinja.dart';

void main() {
  const source = '{% for user in users %}'
      '{{ user["fullname"] }}, {{ user["email"] }}; '
      '{% else %}No users{% endfor %}';

  final env = Environment();
  final template = env.fromSource(source, path: 'index.html');

  print(template.renderWr(users: [
    {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
    {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
  ]));
}
