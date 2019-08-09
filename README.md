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
- Expressions
  - Literals
  - Math
  - Comparison
  - Logic
  - *in*
  - *is* tests
  - *|* filters
  - *(args, kwargs, *args, **kwargs)* call callable
  - *.*/*[]* object attribute (*.* for field, *[]* for map)
  - *... if ... else ...* condition expression
  - *~* concat
- Filters
    - abs
    - attr
    - capitalize
    - center
    - count, length
    - default, d
    - escape, e
    - first
    - float
    - forceescape
    - int
    - join
    - last
    - list
    - lower
    - random
    - string
    - sum
    - trim
    - upper
- Tests
- Statements
  - For (without recursive)
  - If
  - Set
  - Inlcude
  - Extends
  - Block
    - Super
