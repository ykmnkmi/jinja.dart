# Jinja for Dart
[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dev/packages/jinja)

[Jinja][jinja] server-side template engine port for Dart 2.
Variables, expressions, control structures and template inheritance.

## 0.4.0 version is breaking
See `CHANGELOG.md`.

## Documentation
Mostly same as [Jinja](https://jinja.palletsprojects.com/en/3.0.x/templates/)
template documentation. _work in progress_.

## Differences
_work in progress_

Common:
- `BigInt` is not supported

Filters:
- `default` filter compares values with `null`

Tests:
- `defined` and `undefined` tests compares values with `null`
- complex is not supported

## Dynamic invocation
_work in progress_

## Example
```dart
import 'package:jinja/jinja.dart';

// ...

var environment = Environment(blockStart: '...', blockEnd: '...');
var template = env.fromString('...source...');

sink.write(template.render({'key': value}));
```

See also examples with [conduit][conduit_example]
and [reflectable][reflectable_example].

## Status:
### TODO:
- Environment
  - constructor
    - extensions
    - selectAutoescape
  - addExtension
  - compileExpression
- Template
  - stream
- List of Control Structures
  - Macros
  - Call
  - Import
- Loaders
  - PackageLoader
  - ...
- Extensions
  - i18n
  - Expression Statement
  - Loop Controls
  - Debug Statement
- Template compiler
- ...

### Done:
- Variables
- Filters
- Tests
- Comments
- Whitespace Control
- Escaping
- Line Statements
  - Comments
  - Blocks
- Template Inheritance
  - Base Template
  - Child Template
  - Super Blocks
  - Nesting extends
  - Named Block End-Tags
  - Block Nesting and Scope
- HTML Escaping
  - Working with Manual Escaping
  - Working with Automatic Escaping
- List of Control Structures
  - For
  - If
  - Filters
  - Assignments
  - Block Assignments
  - Extends
  - Blocks
  - Include
- Import Context Behavior
- Expressions with [filters][filters] (not all) and [tests][tests]
- List of Global Functions
  - list
  - namespace
  - print
  - range
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Extensions
  - Do Statement
  - With Statement
- Autoescape Overrides

## Contributing
If you found a bug, typo or you have better description or comment
for documents, just create a [new issue][new_issue] or even better
fork and issue a pull request with your fix.

[jinja]: https://www.palletsprojects.com/p/jinja
[conduit_example]: https://github.com/ykmnkmi/jinja_conduit_example
[reflectable_example]: https://github.com/ykmnkmi/jinja_reflectable_example
[filters]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/filters.dart
[tests]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/tests.dart
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new