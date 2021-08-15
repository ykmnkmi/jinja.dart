## 0.4.0-dev.11
- no dynamic template imports, only single constant template path/name.
- `Template.renderMap` now deprecated.
- `Template.render` now accepts `Map<String, Object?>`.
- `FileSystemLoader` moved from `package:jinja/jinja.dart` to `package:jinja/loaders.dart`.
- new statements:
  - with
- internal improvments
- _work in progress_

## 0.3.4
- variables can be written with the `_` character
- internal changes

## 0.3.3
- replace `pedantic` with `lints` package

## 0.3.2
- remove forgotten print

## 0.3.1
- add `FileSystemLoader` autoload filtering

## 0.3.0
- migrate to null safety
- minimal SDK version: 2.12.0
- add `math.Random` `random` field to `Environment` and `Template` classes
- add `encoding` parameter to `FileSystemLoader` constructor
- add loader tests
- template:
  - change `Template.parsed` constructor definition to `Template.parsed(this.env, this.body, [this.path])`
- internal fixes

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
- add and update filters
- update escaping
- update package tests
- formatting & fixes

## 0.0.7+1
- set (one variable assign statement)
- recursive For-Loop
- unpacking argument expression
- formatting & fixes

## 0.0.7
- add global namespace to env and update context
- add all missing builtin tests
- fix expression group parsing
- update package tests
- formatting & fixes

## 0.0.6
- add undefined & env.finalize
- add and switch to env call template, filter, test methods
- add **is** and **in** expressions
- add sum filter
- formatting & fixes

## 0.0.5
- add batch and escape filters
- template and context required env
- environment fromSource can store template
- formatting & fixes

## 0.0.4
- add test for for-loop & if-condition
- add defined filter
- immutable context
- little docs
- formatting & fixes

## 0.0.3
- fixes & formatting
- more filters & tests, package tests

## 0.0.2
- fixes & formatting

## 0.0.1
- base statements, variables, inheritance, filters & tests and example
