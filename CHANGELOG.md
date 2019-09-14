## 0.2.0
- adding token stream
- adding extensions

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
  - add extensions
  - rename:
    - stmtOpen to blockStart
    - stmtClose to blockEnd
    - varOpen to variableStart
    - varClose to variableEnd
    - commentOpen to commentStart
    - commentClose to commentEnd
  - move autoReload to FileSystemLoader
  - remove getFilter and getTest
- update context and parser
- parser:
  - parsing *args, **kwargs in calls (not in filters and tests)
  - custom tags support
  - context
  - onParseName
- template:
  - update render function: render(kv1: ..., kv2: ...) calls renderMap({'kv1': ..., 'kv2': ...})
  - add simple module
  - add self.blockName callback ref in context
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
