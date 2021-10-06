import 'dart:mirrors' show reflect;

Object? fieldGetter(Object? object, String field) {
  var mirror = reflect(object).getField(Symbol(field));
  return mirror.reflectee;
}
