# jinja

[![Pub Package][pub_icon]][pub]
[![Test Status][test_ci_icon]][test_ci]
[![CodeCov][codecov_icon]][codecov]

[Jinja][jinja] server-side template engine port for Dart 2.
Variables, expressions, control structures and template inheritance.

## Version 0.4.0 introduces breaking changes
See `CHANGELOG.md`.

## Documentation
Mostly the same as the [Jinja][jinja_templates] template documentation.
_work in progress_.

## Differences with Python version
- `BigInt` and complex numbers are not supported.
- The `default` filter compares values with `null`; there is no `boolean` parameter.
- The `defined` and `undefined` tests compare values with `null`.
- The `map` filter also compares values with `null`.
  Use `attribute` for fields and `item` for items.
- Not yet supported:
  - nested attributes and items
  - slices and negative indexes
  - conditional and variable `extends` statement variants
  - choice, ignore missing and variable `include` statement variants
- If `Environment({getAttribute})` is not passed, the `getItem` method will be used.
  This allows you to use `{{ map.key }}` as an expression equivalent to `{{ map['key'] }}`.
- _work in progress_

## Dynamically invoked members
- `[]`, `+`, `-`, `*`, `/`, `~/`, `%` operators
- `object.length` getter
- `object.call` getter
- `Function.apply(function, ...)`

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
- Template:
  - generate
  - stream
  - `await` support
- HTML Escaping
  - Automatic
- List of Control Structures
  - Macros 🔥
  - Call 🔥
  - Import
- Loaders
  - PackageLoader (VM)
  - ...
- Extensions
  - i18n
  - Expression Statement
  - Loop Controls
  - Debug Statement
- Template compiler (builder)
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
  - Include
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

## Support
Post issues and feature requests on the GitHub [issue tracker][issues].

[pub_icon]: https://img.shields.io/pub/v/jinja.svg
[pub]: https://pub.dev/packages/jinja
[test_ci_icon]: https://github.com/ykmnkmi/jinja.dart/actions/workflows/test.yaml/badge.svg
[test_ci]: https://github.com/ykmnkmi/jinja.dart/actions/workflows/test.yaml
[codecov_icon]: https://codecov.io/gh/ykmnkmi/jinja.dart/branch/main/graph/badge.svg?token=PRP3DHMO48
[codecov]: https://codecov.io/gh/ykmnkmi/jinja.dart
[jinja]: https://www.palletsprojects.com/p/jinja
[jinja_templates]: https://jinja.palletsprojects.com/en/3.0.x/templates
[conduit_example]: https://github.com/ykmnkmi/jinja_conduit_example
[reflectable_example]: https://github.com/ykmnkmi/jinja_reflectable_example
[filters]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/filters.dart
[tests]: https://github.com/ykmnkmi/jinja.dart/blob/master/lib/src/tests.dart
[issues]: https://github.com/ykmnkmi/jinja.dart/issues