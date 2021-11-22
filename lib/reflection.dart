import 'dart:mirrors' show MirrorSystem, reflect;

/// Reflection based object attribute getter.
Object? fieldGetter(Object? object, String field) {
  var mirror = reflect(object).getField(MirrorSystem.getSymbol(field));
  return mirror.reflectee;
}
