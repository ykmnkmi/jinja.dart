import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('lexer', () {
    Environment env = Environment();

    test('raw', () {
      Template template = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      Template template = env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      Environment env = Environment(leftStripBlocks: true, trimBlocks: true);
      Template template = env.fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.renderWr(baz: 'test'), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      Environment env = Environment(
        blockStart: '{%',
        blockEnd: '%}',
        variableStart: r'${',
        variableEnd: '}',
      );

      Template template = env.fromString(r'''{% for item in seq
            %}${{'foo': item} | upper}{% endfor %}''');
      expect(template.renderWr(seq: <int>[0, 1, 2]), equals("{'FOO': 0}{'FOO': 1}{'FOO': 2}"));
    });

    test('comments', () {
      Environment env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: '{',
        variableEnd: '}',
      );

      Template template = env.fromString('''\
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(template.renderWr(seq: <int>[0, 1, 2]), equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      for (String char in <String>[r'\0', r'\2668', r'\xe4', r'\t', r'\r', r'\n']) {
        Template template = env.fromString('{{ ${repr(char)} }}');
        expect(template.render(), equals(char));
      }

      // TODO: * poor dart
      // expect(env.fromString('{{ "\N{HOT SPRINGS}" }}').render(), equals('\u2668'));
    });
  });

  group('leftStripBlocks', () {
    Environment env = Environment();

    test('lstrip', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals('\n'));
    });

    test('lstrip trim', () {
      Environment env = Environment(leftStripBlocks: true, trimBlocks: true);
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals(''));
    });

    test('no lstrip', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.render(), equals('    \n    '));
      template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.render(), equals('    \n    '));
    });

    test('lstrip endline', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    hello{% if true %}\n    goodbye{% endif %}');
      expect(template.render(), equals('    hello\n    goodbye'));
    });

    test('lstrip inline', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {% if true %}hello    {% endif %}');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip nested', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {% if true %}a {% if true %}b {% endif %}c {% endif %}');
      expect(template.render(), equals('a b c '));
    });

    test('lstrip left chars', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('''    abc {% if true %}
        hello{% endif %}''');
      expect(template.render(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(template.render(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('\n\n\n{% set hello = 1 %}');
      expect(template.render(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      Environment env = Environment(leftStripBlocks: true);
      Template template = env.fromString('''    {# if true #}
hello
    {#endif#}''');
      expect(template.render(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: r'${',
        variableEnd: '}',
        commentStart: '<%#',
        commentEnd: '%>',
        /* '%', '##', */
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('    <% if true %>hello    <% endif %>');
      expect(template.render(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: r'${',
        variableEnd: '}',
        commentStart: '<%#',
        commentEnd: '%>',
        /* '%', '##', */
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('    <%# if true %>hello    <%# endif %>');
      expect(template.render(), equals('hello    '));
    });

// TODO: line comment
//     test('lstrip angle bracket', () {
//       Environment env = Environment(
//         blockStart: '<%',
//         blockEnd: '%>',
//         variableStart: r'${',
//         variableEnd: '}',
//         commentStart: '<%#',
//         commentEnd: '%>',
//         /* '%', '##', */
//         leftStripBlocks: true,
//         trimBlocks: true,
//       );
//       Template template = env.fromString(r'''
//     <%# regular comment %>
//     <% for item in seq %>
// ${item} ## the rest of the stuff
//    <% endfor %>''');
//       expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

// TODO: line comment
//     test('lstrip angle bracket compact', () {
//       Environment env = Environment(
//         blockStart: '<%',
//         blockEnd: '%>',
//         variableStart: r'${',
//         variableEnd: '}',
//         commentStart: '<%#',
//         commentEnd: '%>',
//         /* '%', '##', */
//         leftStripBlocks: true,
//         trimBlocks: true,
//       );
//       Template template = env.fromString(r'''
//     <%#regular comment%>
//     <%for item in seq%>
// ${item} ## the rest of the stuff
//    <%endfor%>''');
//       expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

    test('php syntax with manual', () {
      Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''\
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(template.renderWr(seq: range(5)), equals('01234'));
    });

    test('php syntax', () {
      Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''\
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '        $n\n')));
    });

    test('php syntax compact', () {
      Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''\
    <!-- I'm a comment, I'm not interesting -->
    <?for item in seq?>
        <?=item?>
    <?endfor?>''');
      expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '        $n\n').join()));
    });

    test('erb syntax', () {
      Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
''');
      expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '    $n\n').join()));
    });

    test('erb syntax with manual', () {
      Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(template.renderWr(seq: range(5)), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString('''<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(template.renderWr(seq: range(5)), equals('    01234'));
    });

    test('comment syntax', () {
      Environment env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: r'${',
        variableEnd: '}',
        commentStart: '<!--#',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      Template template = env.fromString(r'''<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(template.renderWr(seq: range(5)), equals('01234'));
    });
  });
}
