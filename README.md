[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)

#### [Jinja](http://jinja.pocoo.org) 2 server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

**Draft**

All variables and literals used in the template are **dart objects** with their own fields and methods.

_Docs is comming_

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
  - *()* call callable
  - *(\*iter)* call callable
  - *.*/*[]* object attribute (*.* for field, *[]* for map)
  - *... if ... else ...* condition expression
  - *~* concat
- Filters
    - attr
    - capitalize
    - center
    - count, length
    - default, d
    - escape, e
    - first
    - forceescape
    - join
    - last
    - list
    - lower
    - random
    - string
    - trim
    - upper
- Tests
- Statements
  - For (without recursive)
  - If
  - Set
  - Template Inheritance
    - Block
      - Super
    - Extends
    - Inlcude
