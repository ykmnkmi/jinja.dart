import 'package:jinja/jinja.dart';

void main() {
  const source = '{% for user in users %}'
      '{{ user["fullname"] }}, {{ user["email"] }}; '
      '{% else %}No users{% endfor %}';

  final env = Environment();
  final template = env.fromSource(source, path: 'index.html');

  print(template.render({
    'users': [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@unknown.dev'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@unknown.dev'},
    ]
  }));
}
