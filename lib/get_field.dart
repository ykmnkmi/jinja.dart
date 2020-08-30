import 'dart:mirrors';

import 'package:jinja/src/exceptions.dart';

dynamic getField(dynamic object, String field) {
  try {
    return reflect(object).getField(Symbol(field)).reflectee;
  } catch (error) {
    // TODO: improve error message
    throw TemplateRuntimeError(error);
  }
}
