import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';

final Environment env = Environment(getAttribute: getAttribute);

final Environment envTrim = Environment(
  getAttribute: getAttribute,
  trimBlocks: true,
);
