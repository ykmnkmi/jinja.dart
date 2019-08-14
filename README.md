[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

#### [Jinja 2](http://jinja.pocoo.org) server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

**Draft**

All variables and literals used in the template are **dart objects** with their own fields and methods.

## Done
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Comments
- Variables
- Expressions: variables, literals, subscription, math, comparison, logic, tests, filters, calls
- Filters
- Tests
- Statements
  - Filter (not all))
  - For (without recursive)
  - If
  - Set
  - Raw
  - Inlcude
  - Extends
  - Block
