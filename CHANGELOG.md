## 0.3.0-dev+1
- add null safety
- add `encoding` parameter to `FileSystemLoader` constructor
- add loader tests
- template:
    - change `Template.parsed` constructor definition to `Template.parsed(this.env, this.body, [this.path])`
- internal fixes
<!-- - issue [7](https://github.com/ykmnkmi/jinja.dart/issues/7) -->

## 0.2.4
- dart issue [41362](https://github.com/dart-lang/sdk/issues/41362)

## 0.2.3
- access map values by field expression `map.key`

## 0.2.2
- default `Environment.getField` returns `null`
- fix list index

## 0.2.1
- add pedantic, format

## 0.2.0
- minimal SDK version: 2.7.0
- add `package:jinja/get_field.dart`
- remove `package:jinja/filters.dart`
- remove `package:jinja/tests.dart`
- environment:
    - `getField` and `getItem` methods
    - `leftStripBlock` and `keepTrailingNewLine` fields
- field and method calling expressions that used mirrors now uses `Environment.getField` method</br>
  default getField throws runtime error, to use field expression based on reflection import and pass to environment `getField` method from `package:jinja/get_field.dart`, or write custom method based on code generation</br>
- filters:
  - add environment filters:
    - batch
    - filesizeformat
- more package tests

## 0.1.2
- fix example

## 0.1.1
- fix template blocks ref

## 0.1.0
- little speed up
- new statements:
  - filter
  - set
  - raw
- add namespace
- environment
  - add leftStrip and trimBlocks
  - add extensions (can change)
  - rename:
    - `stmtOpen` to `blockStart`
    - `stmtClose` to `blockEnd`
    - `varOpen` to `variableStart`
    - `varClose` to `variableEnd`
    - `commentOpen` to `commentStart`
    - `commentClose` to `commentEnd`
  - move `autoReload` to `FileSystemLoader`
  - remove `getFilter` and `getTest`
- update context and parser
- parser:
  - parsing *args, **kwargs in calls (not in filters and tests)
  - custom tags support
  - context
- template:
  - update render function: `render(kv1: ..., kv2: ...)` calls `renderMap({'kv1': ..., 'kv2': ...})`
  - add self namespace and self.blockName callback ref in context
- removed filters:
  - batch
  - filesizeformat

## 0.0.8+1
- Fixes

## 0.0.8
- Add and update filters
- Update escaping
- Update package tests
- Formatting & fixes

## 0.0.7+1
- Set (one variable assign statement)
- Recursive For-Loop
- Unpacking argument expression
- Formatting & fixes

## 0.0.7
- Add global namespace to env and update context
- Add all missing builtin tests
- Fix expression group parsing
- Update package tests
- Formatting & fixes

## 0.0.6
- Add undefined & env.finalize
- Add and switch to env call template, filter, test methods
- Add **is** and **in** expressions
- Add sum filter
- Formatting & fixes

## 0.0.5
- Add batch and escape filters
- Template and context required env
- Environment fromSource can store template
- Formatting & fixes

## 0.0.4
- Add test for for-loop & if-condition
- Add defined filter
- Immutable context
- Little Docs
- Formatting & fixes

## 0.0.3
- Fixes & formatting
- More filters & tests, package tests

## 0.0.2
- Fixes & formatting

## 0.0.1
- Base statements, variables, inheritance, filters & tests and example
