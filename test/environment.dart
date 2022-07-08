import 'package:jinja/jinja.dart';
import 'package:jinja/reflection.dart';

export 'package:jinja/jinja.dart';
export 'package:jinja/src/lexer.dart';
export 'package:jinja/src/markup.dart';
export 'package:jinja/src/nodes.dart';
export 'package:jinja/src/reader.dart';
export 'package:jinja/src/utils.dart';

final Environment env = Environment(fieldGetter: fieldGetter);
