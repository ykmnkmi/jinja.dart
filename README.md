[![Pub](https://img.shields.io/pub/v/jinja.svg)](https://pub.dartlang.org/packages/jinja)
[![Build Status](https://travis-ci.org/ykmnkmi/jinja.dart.svg?branch=master)](https://travis-ci.org/ykmnkmi/jinja.dart)

#### [Jinja](http://jinja.pocoo.org) 2 server-side template engine port for Dart 2. Variables, expressions, control structures and template inheritance.

**Draft**

All variables passed to the template and literals used in the template are **dart objects** with their own fields and methods.

## To Do
- Compile templates to fast Dart code
- Docs
- Informative error output
- Full test coverage
- Add missing filters
- Loaders
  - PackageLoader
  - FunctionLoader
  - PrefixLoader
  - ChoiceLoader
- Whitespace Control
- Escaping
- Line Statements
- Statements
  - Macro
  - Set Block
  - Call
  - Filter
  - Template Inheritance
    - Include
    - Import
- Expressions
  - *... if ... else ...* condition expression
  - *~* concat

## Done
- Loaders
  - FileSystemLoader
  - MapLoader (DictLoader)
- Variables
- Filters
    - length
    - count
    - string
    - escape, e
    - forceescape
    - upper
    - lower
    - capitalize
    - dictsort
    - default
    - d
    - join
    - center
    - first
    - last
    - random
    - filesizeformat
    - int
    - float
    - abs
    - trim
    - batch
    - sum
    - list
    - attr
- Tests
- Comments
- Statements
  - For (not full covered)
  - If
  - Set (one variable statement)
  - Template Inheritance (not covered)
    - Extends
    - Block
      - Super
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
