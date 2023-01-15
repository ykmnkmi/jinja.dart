# jinja

[![Pub Package][pub_icon]][pub]
[![Test Status][test_ci_icon]][test_ci]

[Jinja][jinja] server-side template engine port for Dart 2.
Variables, expressions, control structures and template inheritance.

## 0.4.0 version is breaking
See `CHANGELOG.md`.

## Documentation
Mostly same as [Jinja][jinja_templates] template documentation.
_work in progress_.

## Differences with Python version
- `BigInt` and complex numbers are not supported.
- The `default` filter compares values with `null`, no `boolean` parameter.
- The `defined` and `undefined` tests compares values with `null`.
- The `map` filter compares values with `null`.
  Use `attribute` for fields and `item` for items.
  Nested attributes and items are not supported.
- If  `Environment({getAttribute})` is not passed, `getItem` will be used.
  This allows you to use `{{ map.key }}` as `{{ map['key'] }}` expression.
- _work in progress_

## Dynamically invoked members
- `[]`, `+`, `-`, `*`, `/`, `~/`, `%` operators
- `object.length` getter
- `object.call` getter
- _work in progress_
- also `Function.apply(function, ...)`

## Example
```dart
import 'package:jinja/jinja.dart';

// ...

var environment = Environment(blockStart: '...', blockEnd: '...');
var template = environment.fromString('...source...');
print(template.render({'key': value}));
// or write directly to StringSink (IOSink, HttpResponse, ...)
template.renderTo(stringSink, {'key': value});
```

See also examples with [conduit][conduit_example] and
[reflectable][reflectable_example].

## Status:
### TODO:
- Environment
  - constructor
    - extensions
    - selectAutoescape
  - addExtension
  - compileExpression
  - policies
- List of Control Structures
  - Macros
  - Call
  - Import
- Loaders
  - PackageLoader (VM)
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
  - Manual
  - Automatic
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
for documentation, just create a [new issue][new_issue] or even better
fork and issue a pull request with your fix.

[pub_icon]: https://img.shields.io/pub/v/jinja.svg
[pub]: https://pub.dev/packages/jinja
[test_ci_icon]: https://github.com/ykmnkmi/jinja.dart/actions/workflows/test.yaml/badge.svg
[test_ci]: https://github.com/ykmnkmi/jinja.dart/actions/workflows/test.yaml
[jinja]: https://www.palletsprojects.com/p/jinja
[jinja_templates]: https://jinja.palletsprojects.com/en/3.0.x/templates
[conduit_example]: https://github.com/ykmnkmi/jinja_conduit_example
[reflectable_example]: https://github.com/ykmnkmi/jinja_reflectable_example
[filters]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/filters.dart
[tests]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/tests.dart
[new_issue]: https://github.com/ykmnkmi/jinja.dart/issues