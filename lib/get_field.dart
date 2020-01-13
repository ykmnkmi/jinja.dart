import 'dart:mirrors';

import 'package:jinja/src/exceptions.dart';

Object getField(Object object, String field) {
  try {
    return reflect(object).getField(Symbol(field)).reflectee;
  } catch (e) {
    // TODO: добавить: текст ошибки
    throw TemplateRuntimeError('$e');
  }
}
