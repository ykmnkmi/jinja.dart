# Jinja 2 for Dart 2

[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

[Jinja 2](http://jinja.pocoo.org/) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

## Current

Simplify, remove mirrors, template generators

## Breaking changes

...text_here...

```dart
import 'package:jinja/jinja.dart';
import 'package:jinja/mirrors.dart';
// code ...
var env = Environment(getField: getField, ...);
var template = env.fromString('{{ object.field }}');
```

## Done

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

## Example

Add package to your `pubspec.yaml` as a dependency

```yaml
dependencies:
  jinja: ^0.2.0
```

Import library and use it:

```dart
import 'package:jinja/jinja.dart';
// code ...
var template = Template('...source...', blockStart: '...', ...);
// or
var env = Environment(blockStart: '...', ... );
var template = env.fromString('...source...');

// overrides noSuchMethod
template.render(key: value, ...);
// or
template.renderMap({'key': value, ...});
```

Note: all variables and literals used in the template are **dart objects** with their own fields and methods.

Docs
----
In progress ...

Contributing
------------
If you found a bug, just create a [new issue][new_issue] or even better fork
and issue a pull request with you fix.

[filters]: https://github.com/ykmnkmi/dart-jinja/blob/master/lib/src/filters.dart
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new