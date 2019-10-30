import 'views.dart' as views;

void main() {
  print(views.users.render(
    users: <Map<String, String>>[
      <String, String>{'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      <String, String>{'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'},
    ],
  ));
}
