import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('lexer', () {
    final Environment env = Environment();

    test('raw', () {
      final Template template = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.renderMap(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final Template template =
          env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.renderMap(), equals('123'));
    });

    test('raw3', () {
      final Environment env =
          Environment(leftStripBlocks: true, trimBlocks: true);
      final Template template = env
          .fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.render(baz: 'test'),
          equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template = env.fromString(
          'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.renderMap(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final Environment env = Environment(
        blockStart: '{%',
        blockEnd: '%}',
        variableStart: r'${',
        variableEnd: '}',
      );

      final Template template = env.fromString(r'''{% for item in seq
            %}${{'foo': item} | upper}{% endfor %}''');
      expect(template.render(seq: <int>[0, 1, 2]),
          equals("{'FOO': 0}{'FOO': 1}{'FOO': 2}"));
    });

    test('comments', () {
      final Environment env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: '{',
        variableEnd: '}',
      );

      final Template template = env.fromString('''\
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(template.render(seq: <int>[0, 1, 2]),
          equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      for (String char in <String>[
        r'\0',
        r'\2668',
        r'\xe4',
        r'\t',
        r'\r',
        r'\n'
      ]) {
        final Template template = env.fromString('{{ ${repr(char)} }}');
        expect(template.renderMap(), equals(char));
      }

      // TODO: проверять
      // expect(env.fromString('{{ "\N{HOT SPRINGS}" }}').render(), equals('\u2668'));
    });
  });

  group('leftStripBlocks', () {
    final Environment env = Environment();

    test('lstrip', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template =
          env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals('\n'));
    });

    test('lstrip trim', () {
      final Environment env =
          Environment(leftStripBlocks: true, trimBlocks: true);
      final Template template =
          env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals(''));
    });

    test('no lstrip', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template =
          env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.renderMap(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      Template template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals('    \n    '));
      template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.renderMap(), equals('    \n    '));
    });

    test('lstrip endline', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template =
          env.fromString('    hello{% if true %}\n    goodbye{% endif %}');
      expect(template.renderMap(), equals('    hello\n    goodbye'));
    });

    test('lstrip inline', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template =
          env.fromString('    {% if true %}hello    {% endif %}');
      expect(template.renderMap(), equals('hello    '));
    });

    test('lstrip nested', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template = env.fromString(
          '    {% if true %}a {% if true %}b {% endif %}c {% endif %}');
      expect(template.renderMap(), equals('a b c '));
    });

    test('lstrip left chars', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template = env.fromString('''    abc {% if true %}
        hello{% endif %}''');
      expect(template.renderMap(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template =
          env.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(template.renderMap(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template = env.fromString('\n\n\n{% set hello = 1 %}');
      expect(template.renderMap(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      final Environment env = Environment(leftStripBlocks: true);
      final Template template = env.fromString('''    {# if true #}
hello
    {#endif#}''');
      expect(template.renderMap(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      final Environment env = Environment(
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
      final Template template =
          env.fromString('    <% if true %>hello    <% endif %>');
      expect(template.renderMap(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      final Environment env = Environment(
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
      final Template template =
          env.fromString('    <%# if true %>hello    <%# endif %>');
      expect(template.renderMap(), equals('hello    '));
    });

// TODO: разблокировать: после реализации строковых коментариев
//     test('lstrip angle bracket', () {
//       final Environment env = Environment(
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
//       final Template template = env.fromString(r'''
//     <%# regular comment %>
//     <% for item in seq %>
// ${item} ## the rest of the stuff
//    <% endfor %>''');
//       expect(template.render(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

// TODO: разблокировать: после реализации строковых коментариев
//     test('lstrip angle bracket compact', () {
//       final Environment env = Environment(
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
//       final Template template = env.fromString(r'''
//     <%#regular comment%>
//     <%for item in seq%>
// ${item} ## the rest of the stuff
//    <%endfor%>''');
//       expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

    test('php syntax with manual', () {
      final Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final Template template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(template.render(seq: range(5)), equals('01234'));
    });

    test('php syntax', () {
      final Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final Template template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('php syntax compact', () {
      final Environment env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final Template template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <?for item in seq?>
        <?=item?>
    <?endfor?>''');

      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('erb syntax', () {
      final Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final Template template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
''');

      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '    $n\n').join()));
    });

    test('erb syntax with manual', () {
      final Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final Template template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');

      expect(template.render(seq: range(5)), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      final Environment env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final Template template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');

      expect(template.render(seq: range(5)), equals('    01234'));
    });

    test('comment syntax', () {
      final Environment env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: r'${',
        variableEnd: '}',
        commentStart: '<!--#',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final Template template =
          env.fromString(r'''<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(template.render(seq: range(5)), equals('01234'));
    });
  });
}
