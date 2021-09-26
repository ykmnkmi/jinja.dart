# Jinja for Dart
[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dev/packages/jinja)

[Jinja](https://www.palletsprojects.com/p/jinja/) server-side template engine port for Dart 2.
Variables, expressions, control structures and template inheritance.

## Breaking changes 0.4.0, less dynamic
- no template variable imports.
- no `Template.renderMap`.
- `Template.render` now accepts `Map<String, Object?>`.
- `FileSystemLoader` moved from `package:jinja/jinja.dart` to `package:jinja/loaders.dart`.
- no `Undefined` and `missing`.
- no slices and negative indexes.
- _work in progress_

## Documentation

Mostly same as [Jinja](https://jinja.palletsprojects.com/en/3.0.x/templates/) template documentation.

## Differences
_work in progress_

## Example
```dart
import 'package:jinja/jinja.dart';

// ...

final environment = Environment(blockStart: '...', blockEnd: '...');
final template = env.fromString('...source...');

sink.write(template.render({'key': value}));
```

See also examples with [conduit][conduit_example] and [reflectable][reflectable_example].

## Status:
### TODO:
- Environment
  - constructor
    - extensions
    - selectAutoescape
  - addExtension
  - compileExpression
  - shared
- Template
  - generate
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
- ... working

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
- Expressions
- List of Builtin Filters
  - abs
  - attr
  - batch
  - capitalize
  - center
  - default, d
  - escape, e
  - filesizeformat
  - first
  - float
  - forceescape
  - int
  - join
  - last
  - length, count
  - list
  - lower
  - random
  - replace
  - reverse
  - safe
  - string
  - sum
  - trim
  - upper
  - wordwrap
- List of Builtin Tests
  - boolean
  - callable
  - defined
  - divisibleby
  - eq, equalto, ==
  - escaped
  - even
  - false
  - float
  - ge, >=
  - gt, greaterthan, >
  - in
  - integer
  - iterable
  - le, <=
  - lower
  - lt, lessthan, <
  - mapping
  - ne, !=
  - none, undefined
  - number
  - odd
  - sameas
  - sequence
  - string
  - true
  - upper
- List of Global Functions
  - list
  - namespace
  - range
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Extensions
  - With Statement
- Autoescape Overrides

## Contributing
If you found a bug, just create a [new issue][new_issue] or even better fork and issue a pull request with your fix.

[conduit_example]: https://github.com/ykmnkmi/jinja_conduit_example
[reflectable_example]: https://github.com/ykmnkmi/jinja_reflectable_example
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new