import 'package:jinja/jinja.dart';

late final env = Environment();

Template parse(String source) {
  return env.fromString(source);
}
