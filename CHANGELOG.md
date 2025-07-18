## 0.6.4 ([diff](https://github.com/ykmnkmi/jinja.dart/compare/1c0015b..main))
- Refactoring.

## 0.6.3 ([diff](https://github.com/ykmnkmi/jinja.dart/compare/e686f50..1c0015b))
- Fix `autoReload` logic.
- Refactoring.

## 0.6.2 ([diff](https://github.com/ykmnkmi/jinja.dart/compare/3464f33..e686f50))
- Added:
  - Statements:
    - `try-catch` block:
      ```jinja
      {% try %}
        {{ x / y }}
      {% catch exception %}
        {{ exception | runtimetype }}: {{ exception }}
      {% endtry %}
      ```
  - Filters:
    - `runtimetype`

## 0.6.1 ([diff](https://github.com/ykmnkmi/jinja.dart/compare/88996f8..3464f33))
- Added:
  - List slices `{{ list[start:stop] }}`.
  - `UndefinedError` exception
  - `UndefinedFactory` typedef
  - `Environment`:
    - `Environment({UndefinedFactory undefined})` argument
    - `UndefinedFactory undefined` field
  - `Template`:
    - `Template({UndefinedFactory undefined})` argument
  - Filters:
    - `null` (`none` alias)

## 0.6.0 ([diff](https://github.com/ykmnkmi/jinja.dart/compare/c12244e6..88996f8))
- Bump SDK version to 3.3.0.
- Update dependencies.
- Internal changes.
- `chrome` platform tests.
- Added:
  - Statements:
    - `import`
    - `from`
  - `Template`:
    - `Template.fromNode({globals})` argument
    - `globals` field
- Restored:
  - Conditional and variable `extends` statement variants
  - Choice, ignore missing and variable `include` statement variants
- Changed:
  - `Environment`:
    - `Environment.lex()` return from `List<Token>` to `Iterable<Token>`
    - `Environment.scan(tokens)` argument type from `List<Token>` to `Iterable<Token>`
- Removed:
  - Exceptions:
    - `FilterArgumentError`
  - `*args` and `**kwargs` support

## 0.5.0
- Minimal SDK version: 3.0.0.
- Internal changes.
- Added:
  - `Template`:
    - `Template.fromNode(Environment environment, {String? path, required Node body})` constructor
  - Statements:
    - `macro`
    - `call`
  - Filters:
    - `items`
    - `title`
- Changed:
  - `Environment`:
    - `Environment({modifiers})` argument type from `List<NodeVisitor>` to `List<Node Function(Node)>`
    - `modifiers` type from `List<NodeVisitor>` to `List<Node Function(Node)>`
    - `scan(...)` return type from `List<Node>` to `Node`
    - `parse(...)` return type from `List<Node>` to `Node`
  - `Template`:
    - `Template({modifiers})` argument type from `List<NodeVisitor>` to `List<Node Function(Node)>`
  - Filters:
    - `truncate` arguments are now positional
- Removed:
  - `Template`:
    - `Template.fromNodes(...)` constructor
  - Statements:
    - `autoescape`
  - Filters:
    - `forceescape`
    - `safe`
    - `unsafe`
  - Tests:
    - `escaped`

## 0.4.2
- Internal changes.

## 0.4.1
- Update links.

## 0.4.0
- Minimal SDK version: 2.18.0.
- Added:
  - `passContext` and `passEnvironment` functions
  - `print` to globals `{{ do print(name) }}`
  - `Environment`
    - `Environment({lineCommentPrefix, lineStatementPrefix, newLine, autoReload, modifiers, templates})` constructor arguments
    - `autoReload` field
    - `lexer` field
    - `lineCommentPrefix` field
    - `lineStatementPrefix` field
    - `loader` field
    - `modifiers` field
    - `newLine` field
    - `lex` method
    - `scan` method
    - `parse` method
  - `Template`
    - `Template({path, lineCommentPrefix, lineStatementPrefix, newLine, modifiers, templates})` constructor arguments
    - `renderTo` method
  - Exceptions (was internal):
    - `TemplateError`
    - `TemplateSyntaxError`
    - `TemplateAssertionError`
    - `TemplateNotFound`
    - `TemplatesNotFound`
    - `TemplateRuntimeError`
    - `FilterArgumentError`
  - Statements:
    - `do`
    - `with`
  - Filters:
    - `dictsort`
    - `replace`
    - `reverse`
    - `safe`
    - `slice`
    - `striptags`
    - `truncate`
    - `wordcount`
    - `wordwrap`
    - `item`
    - `map`
    - `tojson`
  - Test:
    - `filter`
    - `test`
- Changed:
  - `FieldGetter` type definition renamed to `AttributeGetter`
  - `default` filter compare values with `null`, no boolean argument
  - `defined` and `undefined` tests compare values with `null`
  - `Environment`
    - `Environment({getField})` constructor argument renamed to `getAttribute`
    - `getField` field renamed to `getAttribute`
  - `Template`
    - `Template({parent})` constructor argument renamed to `environment`
      and doesn't copy the environment
    - `renderMap` method renamed to `render`
  - `Loader.listSources` method renamed to `listTemplates`
  - `MapLoader.mapping` field renamed to  `sources`
  - `FileSystemLoader`
    - `FileSystemLoader({paths})` argument is now non-nullable, defaults to `['templates']`
    - moved to `package:jinja/loaders.dart` library
  - `package:jinja/get_field.dart` library renamed to `package:jinja/reflection.dart`
  - `getField` function renamed to `getAttribute`
- Removed:
  - `Undefined` type and `missing` object
  - `Environment.undefined` method
  - `Template.render` method
  - `FileSystemLoader`:
    - `FileSystemLoader({path, autoReload})` arguments
    - `autoReload` field
    - `directory` field
  - Slices and negative indexes
  - Conditional and variable `extends` statement variants
  - Choice, ignore missing and variable `include` statement variants
- Internal changes