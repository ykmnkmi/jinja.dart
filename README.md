# Jinja for Dart

[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

[Jinja](https://www.palletsprojects.com/p/jinja/) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

Breaking changes
----------------
Before `object.field` or `object.method()` expressions uses `dart:mirrors` methods.
```dart
import 'package:jinja/jinja.dart';

// ...

final Environment env = Environment( /* ... */ );
final Template template = env.fromString('{{ users[0].name }}');

// ...

outStringSink.write(template.render(users: listOfUsers));
// outStringSink.write(template.renderMap({'users': listOfUsers}));
```

Now to access the fields and methods of the object, (except namespase, loop, self), you need to import the `get_field` method from the `package:jinja/get_field.dart` file and pass it to the `Environment` constructor.
Or create or use another method for accessing.
```dart
import 'package:jinja/jinja.dart';

import 'package:jinja/get_field.dart' show getField;

// ...

final Environment = Environment(getField: getField, /* ... */ );
final Template template = env.fromString('{{ users[0].name }}');

// ...

outStringSink.write(template.render(users: listOfUsers));
// outStringSink.write(template.renderMap({'users': listOfUsers}));
```

Done
----
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Comments
- Variables
- Expressions: variables, literals, subscription, math, comparison, logic, tests, filters, calls
- Filters (not all, see [here][filters])
- Tests
- Statements
  - Filter
  - For (without recursive)
  - If
  - Set
  - Raw
  - Inlcude
  - Extends
  - Block

Example
-------
Add package to your `pubspec.yaml` as a dependency

```yaml
dependencies:
  jinja: ^0.2.0
```

Import library and use it:

```dart
import 'package:jinja/jinja.dart';

// code ...

final Environment = Environment(blockStart: '...');
final Template template = env.fromString('...source...');

outStringSink.write(template.render(key: value));
// outStringSink.write(template.renderMap({'key': value}));
```

Note
----
Why is this [hack][hack] used?

In the final version for the production version, templates will be
generated and the render function will have named parameters that
are used in the template code

Second option, create new packages:
  - jinja_core - core, filters, tests, utils
  - jinja_config - yaml based environment config
  - jinja_generator - generate _pure_ dart code
  - jinja_nodes - or use nodes

Docs
----
In progress ...

Contributing
------------
If you found a bug, just create a [new issue][new_issue] or even better fork
and issue a pull request with your fix.

[filters]: https://github.com/ykmnkmi/dart-jinja/blob/master/lib/src/filters.dart
[hack]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/environment.dart#L355
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new