import 'dart:mirrors';

import 'package:jinja/src/exceptions.dart';

Object? getField(Object? object, String field) {
  try {
    return reflect(object).getField(Symbol(field)).reflectee;
  } catch (error) {
    // TODO: improve error message
    throw TemplateRuntimeError(error);
  }
}
