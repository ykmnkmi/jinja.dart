import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

void main() {
  group('Parser', () {
    test('php syntax', () {
      var env = Environment(
          blockStart: '<?',
          blockEnd: '?>',
          variableStart: '<?=',
          variableEnd: '?>',
          commentStart: '<!--',
          commentEnd: '-->');
      var tmpl = env.fromString('<!-- I\'m a comment -->'
          '<? for item in seq -?>\n    <?= item ?>\n<?- endfor ?>');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('erb syntax', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: '<%=',
          variableEnd: '%>',
          commentStart: '<%#',
          commentEnd: '%>');
      var tmpl = env.fromString('<%# I\'m a comment %>'
          '<% for item in seq -%>\n    <%= item %><%- endfor %>');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('comment syntax', () {
      var env = Environment(
          blockStart: '<!--',
          blockEnd: '-->',
          variableStart: '\${',
          variableEnd: '}',
          commentStart: '<!--#',
          commentEnd: '-->');
      var tmpl = env.fromString('<!--# I\'m a comment -->'
          '<!-- for item in seq --->    \${item}<!--- endfor -->');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('balancing', () {
      var tmpl = env.fromString('''{{{'foo':'bar'}.foo}}''');
      expect(tmpl.render(), equals('bar'));
    });

    // TODO: after macro: enable test
    // test('start comment', () {
    //   var tmpl = env.fromString('{# foo comment\nand bar comment #}'
    //       '{% macro blub() %}foo{% endmacro %}\n{{ blub() }}');
    //   expect(tmpl.render().trim(), equals('foor'));
    // });

    test('line syntax', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: '\${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%');
      var sequence = range(5).toList();
      var tmpl = env.fromString('<%# regular comment %>\n% for item in seq:\n'
          '    \${item} ## the rest of the stuff\n% endfor');
      var result = tmpl
          .render({'seq': sequence})
          .split(RegExp('\\s+'))
          .map((string) => string.trim())
          .where((string) => string.isNotEmpty)
          .map((string) => int.parse(string.trim()))
          .toList();
      expect(result, equals(sequence));
    });

    test('line syntax priority', () {
      var seq = [1, 2];
      var env = Environment(
          variableStart: '\${',
          variableEnd: '}',
          commentStart: '/*',
          commentEnd: '*/',
          lineCommentPrefix: '#',
          lineStatementPrefix: '##');
      var tmpl =
          env.fromString('/* ignore me.\n   I\'m a multiline comment */\n'
              '## for item in seq:\n* \${item}          '
              '# this is just extra stuff\n## endfor\n');
      expect(tmpl.render({'seq': seq}).trim(), equals('* 1\n* 2'));
      env = Environment(
          variableStart: '\${',
          variableEnd: '}',
          commentStart: '/*',
          commentEnd: '*/',
          lineCommentPrefix: '##',
          lineStatementPrefix: '#');
      tmpl = env.fromString('/* ignore me.\n   I\'m a multiline comment */\n'
          '# for item in seq:\n* \${item}          '
          '## this is just extra stuff\n    '
          '## extra stuff i just want to ignore\n# endfor');
      expect(tmpl.render({'seq': seq}).trim(), equals('* 1\n\n* 2'));
    });

    test('error messages', () {
      void assertError(String source, String expekted) {
        expect(
            () => env.fromString(source),
            throwsA(predicate<TemplateSyntaxError>(
                (error) => error.message == expekted)));
      }

      assertError(
          '{% for item in seq %}...{% endif %}',
          'Encountered unknown tag \'endif\'. Jinja was looking '
              'for the following tags: \'endfor\' or \'else\'. The '
              'innermost block that needs to be closed is \'for\'.');
      assertError(
          '{% if foo %}{% for item in seq %}...{% endfor %}{% endfor %}',
          'Encountered unknown tag \'endfor\'. Jinja was looking for '
              'the following tags: \'elif\' or \'else\' or \'endif\'. The '
              'innermost block that needs to be closed is \'if\'.');
      assertError(
          '{% if foo %}',
          'Unexpected end of template. Jinja was looking for the '
              'following tags: \'elif\' or \'else\' or \'endif\'. The '
              'innermost block that needs to be closed is \'if\'.');
      assertError(
          '{% for item in seq %}',
          'Unexpected end of template. Jinja was looking for the '
              'following tags: \'endfor\' or \'else\'. The innermost block '
              'that needs to be closed is \'for\'.');
      assertError('{% block foo-bar-baz %}', 'use an underscore instead');
      assertError(
          '{% unknown_tag %}', 'Encountered unknown tag \'unknown_tag\'.');
    });
  });
}
