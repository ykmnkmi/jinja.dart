import 'package:jinja/jinja.dart';

const String base = '''{% block title %}Title{% endblock %}
{% block content %}Content{% endblock %}
''';

const String users = '''{% extends "base.html" %}
{% block title %}
  {{ super() }}: users, {{ now() }}
{% endblock %}
{% block content %}
  {% for user in users %}
    {{ user["fullname"] }}, email: {{ user["email"] }}
  {% else %}
    No users
  {% endfor %}
{% endblock %}
''';

void main() {
  Environment env = Environment(
    globals: {
      'now': () {
        DateTime dt = DateTime.now().toLocal();
        String hour = dt.hour < 10 ? '0${dt.hour}' : dt.hour.toString();
        String minute = dt.minute < 10 ? '0${dt.minute}' : dt.minute.toString();
        return '$hour:$minute';
      },
    },
    loader: MapLoader({
      'base.html': base,
      'users.html': users,
    }),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  Template template = env.getTemplate('users.html');

  print(template.render({
    'users': [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ],
  }));
}
