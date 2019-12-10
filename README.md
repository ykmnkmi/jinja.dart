# Jinja 2 for Dart 2

[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

[Jinja 2](http://jinja.pocoo.org/) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

Current status
-------
Token based parser, extensions, template generator

Breaking changes
----------------
Current:
For field and object methods
```dart
import 'package:jinja/jinja.dart';

// ...

var env = Environment( /* ... */ );
var template = env.fromString('{{ users[0].name }}');

// ...

outStringSink.write(template.renderMap({'users': listOfUsers}));
// outStringSink.write(template.render(users: listOfUsers));
```

Now:
```dart
import 'package:jinja/jinja.dart';
// for field expression
import 'package:jinja/get_field.dart' show getField;

// ...

var env = Environment(getField: getField, /* ... */ );
var template = env.fromString('{{ users[0].name }}');

// ...

outStringSink.write(template.renderMap({'users': listOfUsers}));
// outStringSink.write(template.render(users: listOfUsers));
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

var env = Environment(blockStart: '...');
var template = env.fromString('...source...');

template.render({'key': value});
// or (overrides noSuchMethod)
template.renderWr(key: value);
```

Docs
----
In progress ...

Contributing
------------
If you found a bug, just create a [new issue][new_issue] or even better fork
and issue a pull request with your fix.

[filters]: https://github.com/ykmnkmi/dart-jinja/blob/master/lib/src/filters.dart
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new