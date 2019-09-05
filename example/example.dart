import 'package:jinja/jinja.dart';

const base = '''{% block title %}Title{% endblock %}
{% block content %}Content{% endblock %}
''';

const users = '''{% extends "base.html" %}
{% block title %}
  {{ super() }}: users
{% endblock %}
{% block content %}
  {% for user in users %}
    |{{ user["fullname"] }}, email: {{ user["email"] }}
  {% else %}
    No users
  {% endfor %}
{% endblock %}
''';

void main() {
  final env = Environment(
    loader: MapLoader({
      'base.html': base,
      'users.html': users,
    }),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  final template = env.getTemplate('users.html');

  print(template.render(
    users: [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ],
  ));
}
