# Jinja 2 for Dart 2

[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

[Jinja 2](jinja) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

Done
----
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Comments
- Variables
- Expressions: variables, literals, subscription, math, comparison, logic, tests, filters, calls
- Filters (not all)
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

Using it
--------
Add package to your `pubspec.yaml` as a dependency

      dependencies:
        jinja: ^0.1.0

Import library and use it:

```dart
import 'package:jinja/jinja.dart';

// code ...

var template = Template('...source...');
// or
var env = Environment(blockStart: '...', ... );
var template = env.fromString('...source...');

template.render(key: value, );
// or 
template.renderMap({ 'key': value, });
```

Note: all variables and literals used in the template are **dart objects** with their own fields and methods.

Docs
----
In progress ...

Contributing
------------
If you found a bug, just create a [new issue][new_issue] or even better fork
and issue a pull request with you fix.

[jinja]: http://jinja.pocoo.org/
[new_issue]: https://github.com/ymknkmi/dart-jinja/issues/new