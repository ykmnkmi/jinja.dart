library jinja.reflection;

import 'dart:mirrors' show MirrorSystem, reflect;

/// Reflection based object attribute getter.
Object? getAttribute(String field, Object? object) {
  var symbol = MirrorSystem.getSymbol(field);
  var mirror = reflect(object).getField(symbol);
  return mirror.reflectee;
}
