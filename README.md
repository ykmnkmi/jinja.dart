# jinja

[![Pub Package][pub_icon]][pub]
[![Test Status][test_ci_icon]][test_ci]
[![CodeCov][codecov_icon]][codecov]

[Jinja][jinja] (3.x) server-side template engine port for Dart 2.
Variables, expressions, control structures and template inheritance.

## Version 0.6.0 introduces breaking changes
- `FilterArgumentError` error class removed
- `*args` and `**kwargs` arguments support removed
- Auto-escaping and related statements, filters and tests have been removed due to the impossibility of extending `String`.
  Use the `escape` filter manually or escape values before passing them to the template.

For more information, see `CHANGELOG.md`.

## Documentation
It is mostly similar to [Jinja][jinja_templates] templates documentation, differences provided below.

_work in progress_.

## Differences with Python version
- The `default` filter compares values with `null`.
- The `defined` and `undefined` tests compare values with `null`.
- The `map` filter also compares values with `null`.
  Use `attribute` and `item` filters for `object.attribute` and `object[item]` expressions.
- If `Environment({getAttribute})` is not passed, the `getItem` method will be used.
  This allows you to use `{{ map.key }}` as an expression equivalent to `{{ map['key'] }}`.
- Slices and negative indexes are not supported.
- Macro arguments without default values are required.
- Not yet implemented:
  - Choice and ignore missing `include` statement variants.
- Not supported:
  - Template module.
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
- `Template` class:
  - `generate` method
  - `stream` method
- Relative template Paths
- Async Support
- Expressions
  - Dart Methods and Properties
    - `!.`/`?.`
- Loaders
  - PackageLoader (VM)
  - ...
- List of Global Functions
  - `lipsum`
  - `dict`
  - `cycler`
  - `joiner`
- Extensions
  - i18n
  - Loop Controls
  - Debug Statement
- Template compiler (builder)
- ...

### Done:
**Note**: ~~item~~ - _not supported_
- Variables
- Filters
  - ~~`forceescape`~~
  - ~~`safe`~~
  - ~~`unsafe`~~
- Tests
  - ~~`escaped`~~
- Comments
- Whitespace Control
- Escaping (only `escape` filter)
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
  - Required Blocks
  - Template Objects
- ~~HTML Escaping~~
- List of Control Structures
  - For
  - If
  - Macro
  - Call
  - Filters
  - Assignments
  - Block Assignments
  - Extends
  - Blocks
  - Include
  - Import
- Import Context Behavior
- Expressions with [filters][filters] and [tests][tests]
  - Literals
    - `"Hello World"`
    - `42` / `123_456`
    - `42.23` / `42.1e2` / `123_456.789`
    - `['list', 'of', 'objects']`
    - `('tuple', 'of', 'values')`
    - `{'dict': 'of', 'key': 'and', 'value': 'pairs'}`
    - `true` / `false`
  - Math
    - `+`
    - `-`
    - `/`
    - `//`
    - `%`
    - `*`
    - `**`
  - Comparisons
    - `==`
    - `!=`
    - `>`
    - `>=`
    - `<`
    - `<=`
  - Logic
    - `and`
    - `or`
    - `not`
    - `(expr)`
  - Other Operators
    - `in`
    - `is`
    - `|`
    - `~`
    - `()`
    - `.`/`[]`
  - If Expression
    - `{{ list.last if list }}`
    - `{{ user.name if user else 'Guest' }}`
  - Dart Methods and Properties (with reflection)
    - `{{ string.toUpperCase() }}`
    - `{{ list.add(item) }}`
- List of Global Functions
  - `print`
  - `range`
  - `list`
  - `namespace`
- Loaders
  - `FileSystemLoader`
  - `MapLoader` (`DictLoader`)
- Extensions
  - Expression Statement
  - With Statement
- ~~Autoescape Overrides~~

## Contributing
Contributions are welcome! Please open an issue or pull request on GitHub.
Look at the ToDo list and comments in the code for ideas on what to work on.
There are no strict rules, but please try to follow the existing code style.

As non-native English speaker and learner, I will be grateful for any
corrections in the documentation and code comments.

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