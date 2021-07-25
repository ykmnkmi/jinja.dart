@Deprecated('Import reflection instead. Will be removed in 0.5.0.')
library get_field;

import 'reflection.dart';

export 'reflection.dart';

@Deprecated('Use `fieldGetter` instead. Will be removed in 0.5.0.')
Object? Function(Object? object, String field) get getField {
  return fieldGetter;
}
