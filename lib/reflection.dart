import 'dart:mirrors' show reflect;

Object? fieldGetter(dynamic object, String field) {
  var mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}
