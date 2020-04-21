import 'dart:mirrors';

import 'package:jinja/src/exceptions.dart';

Object getField(Object object, String field) {
  try {
    return reflect(object).getField(Symbol(field)).reflectee;
  } catch (e) {
    // TODO: добавить: текст ошибки = add: error message
    throw TemplateRuntimeError('$e');
  }
}

extension on Map {
  Object items() {
    return entries.map((entry) => <Object>[entry.key, entry.value]);
  }
}
