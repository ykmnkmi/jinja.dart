# Jinja for Dart

[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dev/packages/jinja)

[Jinja](https://www.palletsprojects.com/p/jinja/) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

## Breaking changes 0.4
- No dynamic template imports. Only single constant template path/name.
- _work in progress_

## Example
```dart
import 'package:jinja/jinja.dart';

// ...

final environment = Environment(blockStart: '...', blockEnd: '...');
final template = env.fromString('...source...');

sink.write(template.render({'key': value}));
```

## Status:
### ToDo:
- Environment
  - constructor
    - ~~extensions~~
    - ~~selectAutoescape~~
  - ~~addExtension~~
  - ~~compileExpression~~
  - ~~shared~~
- Template
  - ~~generate~~
  - ~~stream~~
- Loaders
  - ~~PackageLoader~~
  - ...
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
  - ~~Macros~~
  - ~~Call~~
  - ~~Filters~~
  - Assignments
  - Block Assignments
  - Extends
  - Blocks
  - Include
  - ~~Import~~
- Import Context Behavior
- Expressions
  - Literals: null (none), true (True), false (False), 1_000, 1.1e3, 'sq', "dq", (1,), \[2\], {'k': 'v'}
  - Math
  - Comparisons
  - Logic
  - Other Operators
  - If Expression
  - Dart Methods
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
  - pprint: bool, num, String, List, Map, Set
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
  - none
  - number
  - odd
  - sameas
  - sequence
  - string
  - true
  - undefined
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
  - ~~i18n~~
  - ~~Expression Statement~~
  - ~~Loop Controls~~
  - ~~Debug Statement~~
- Autoescape Overrides

## Contributing
If you found a bug, just create a [new issue][new_issue] or even better fork and issue a pull request with your fix.

[jinja_reflectable_example]: https://github.com/ykmnkmi/jinja_reflectable_example/blob/master/bin/main.dart
[filters]: https://github.com/ykmnkmi/dart-jinja/blob/master/lib/src/filters.dart
[hack]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/environment.dart#L299
[renderable]: https://github.com/ykmnkmi/renderable.dart
[new_issue]: https://github.com/ykmnkmi/dart-jinja/issues/new