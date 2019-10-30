import 'dart:mirrors';

Object getField(Object object, String field) =>
    reflect(object).getField(Symbol(field)).reflectee;
