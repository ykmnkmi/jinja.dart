import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

void main() {
  group('Parser', () {
    test('php syntax', () {
      final environment = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: '<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
      );

      expect(
          environment
              .fromString('<!-- I\'m a comment, I\'m not interesting -->'
                  '<? for item in seq -?>\n    <?= item ?>\n<?- endfor ?>')
              .render({'seq': range(5)}),
          equals('01234'));
    });

    test('erb syntax', () {
      final environment = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '<%=',
        variableEnd: '%>',
        commentBegin: '<%#',
        commentEnd: '%>',
      );

      expect(
          environment
              .fromString('<%# I\'m a comment, I\'m not interesting %>'
                  '<% for item in seq -%>\n    <%= item %><%- endfor %>')
              .render({'seq': range(5)}),
          equals('01234'));
    });

    test('comment syntax', () {
      final environment = Environment(
        blockBegin: '<!--',
        blockEnd: '-->',
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '<!--#',
        commentEnd: '-->',
      );

      expect(
          environment
              .fromString('<!--# I\'m a comment, I\'m not interesting -->'
                  '<!-- for item in seq --->    \${item}<!--- endfor -->')
              .render({'seq': range(5)}),
          equals('01234'));
    });

    test('balancing', () {
      expect(render('''{{{'foo':'bar'}.foo}}'''), equals('bar'));
    });

    // TODO: after macro: enable test
    test('start comment', () {
      expect(
          render('{# foo comment\nand bar comment #}'
                  '{% macro blub() %}foo{% endmacro %}\n{{ blub() }}')
              .trim(),
          equals('foor'));
    }, skip: true);

    test('line syntax', () {
      final environment = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
      );

      final sequence = range(5).toList();
      expect(
          environment
              .fromString('<%# regular comment %>\n% for item in seq:\n'
                  '    \${item} ## the rest of the stuff\n% endfor')
              .render({'seq': sequence})
              .split(RegExp('\\s+'))
              .map((string) => string.trim())
              .where((string) => string.isNotEmpty)
              .map((string) => int.parse(string.trim()))
              .toList(),
          equals(sequence));
    });

    test('line syntax priority', () {
      var environment = Environment(
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '/*',
        commentEnd: '*/',
        lineCommentPrefix: '#',
        lineStatementPrefix: '##',
      );

      expect(
          environment
              .fromString('/* ignore me.\n   I\'m a multiline comment */\n'
                  '## for item in seq:\n* \${item}          '
                  '# this is just extra stuff\n## endfor\n')
              .render({
            'seq': [1, 2]
          }).trim(),
          equals('* 1\n* 2'));

      environment = Environment(
        variableBegin: '\${',
        variableEnd: '}',
        commentBegin: '/*',
        commentEnd: '*/',
        lineCommentPrefix: '##',
        lineStatementPrefix: '#',
      );

      expect(
          environment
              .fromString('/* ignore me.\n   I\'m a multiline comment */\n'
                  '# for item in seq:\n* \${item}          '
                  '## this is just extra stuff\n    '
                  '## extra stuff i just want to ignore\n# endfor')
              .render({
            'seq': [1, 2]
          }).trim(),
          equals('* 1\n\n* 2'));
    });

    test('error messages', () {
      void assertError(String source, String expekted) {
        void callback() {
          Template(source);
        }

        expect(
            callback,
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
