import 'package:jinja/jinja.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('lexer', () {
    final env = Environment();

    test('raw', () {
      final template = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.renderMap(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final template =
          env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.renderMap(), equals('123'));
    });

    test('raw3', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final template = env
          .fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.render(baz: 'test'),
          equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString(
          'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.renderMap(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final env = Environment(
        blockStart: '{%',
        blockEnd: '%}',
        variableStart: r'${',
        variableEnd: '}',
      );

      final template = env.fromString(r'''{% for item in seq
            %}${{'foo': item} | string | upper}{% endfor %}''');
      expect(template.render(seq: <int>[0, 1, 2]),
          equals("{'FOO': 0}{'FOO': 1}{'FOO': 2}"));
    });

    test('comments', () {
      final env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: '{',
        variableEnd: '}',
      );

      final template = env.fromString('''\
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(template.render(seq: <int>[0, 1, 2]),
          equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      for (var char in <String>['\0', '\2668', '\xe4', '\t', '\r', '\n']) {
        final template = env.fromString('{{ ${repr(char)} }}');
        expect(template.renderMap(), equals(char));
      }

      // TODO: waiting for a realization in the dart sdk
      // expect(env.fromString('{{ "\N{HOT SPRINGS}" }}').render(), equals('\u2668'));
    });

    // TODO: check: after implementing Environment.newlineSequence
    // test('normalizing', () {
    //   for (var seq in <String>['\r', '\r\n', '\n']) {
    //     final env = Environment(newlineSequence: seq);
    //     final template = env.fromString('1\n2\r\n3\n4\n');
    //     expect(template.renderMap().replaceAll(seq, 'X'), equals('1X2X3X4'));
    //   }
    // });
  });

  group('leftStripBlocks', () {
    final env = Environment();

    test('lstrip', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals('\n'));
    });

    test('lstrip trim', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals(''));
    });

    test('no lstrip', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.renderMap(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      var template = env.fromString('    {% if true %}\n    {% endif %}');
      expect(template.renderMap(), equals('    \n    '));
      template = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(template.renderMap(), equals('    \n    '));
    });

    test('lstrip endline', () {
      final env = Environment(leftStripBlocks: true);
      final template =
          env.fromString('    hello{% if true %}\n    goodbye{% endif %}');
      expect(template.renderMap(), equals('    hello\n    goodbye'));
    });

    test('lstrip inline', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('    {% if true %}hello    {% endif %}');
      expect(template.renderMap(), equals('hello    '));
    });

    test('lstrip nested', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString(
          '    {% if true %}a {% if true %}b {% endif %}c {% endif %}');
      expect(template.renderMap(), equals('a b c '));
    });

    test('lstrip left chars', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('''    abc {% if true %}
        hello{% endif %}''');
      expect(template.renderMap(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(template.renderMap(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('\n\n\n{% set hello = 1 %}');
      expect(template.renderMap(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      final env = Environment(leftStripBlocks: true);
      final template = env.fromString('''    {# if true #}
hello
    {#endif#}''');
      expect(template.renderMap(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      final env = Environment(
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
      final template = env.fromString('    <% if true %>hello    <% endif %>');
      expect(template.renderMap(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      final env = Environment(
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
      final template =
          env.fromString('    <%# if true %>hello    <%# endif %>');
      expect(template.renderMap(), equals('hello    '));
    });

// TODO: check: after implementing comments
//     test('lstrip angle bracket', () {
//       final env = Environment(
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
//       final template = env.fromString(r'''
//     <%# regular comment %>
//     <% for item in seq %>
// ${item} ## the rest of the stuff
//    <% endfor %>''');
//       expect(template.render(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

// TODO: check: after implementing comments
//     test('lstrip angle bracket compact', () {
//       final env = Environment(
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
//       final template = env.fromString(r'''
//     <%#regular comment%>
//     <%for item in seq%>
// ${item} ## the rest of the stuff
//    <%endfor%>''');
//       expect(template.renderWr(seq: range(5)), equals(range(5).map((int n) => '$n\n').join()));
//     });

    test('php syntax with manual', () {
      final env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(template.render(seq: range(5)), equals('01234'));
    });

    test('php syntax', () {
      final env = Environment(
        blockStart: '<?',
        blockEnd: 'jbg',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('php syntax compact', () {
      final env = Environment(
        blockStart: '<?',
        blockEnd: '?>',
        variableStart: '<?=',
        variableEnd: '?>',
        commentStart: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final template =
          env.fromString('''<!-- I'm a comment, I'm not interesting -->
    <?for item in seq?>
        <?=item?>
    <?endfor?>''');

      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '        $n\n').join()));
    });

    test('erb syntax', () {
      final env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
''');

      expect(template.render(seq: range(5)),
          equals(range(5).map<String>((int n) => '    $n\n').join()));
    });

    test('erb syntax with manual', () {
      final env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');

      expect(template.render(seq: range(5)), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      final env = Environment(
        blockStart: '<%',
        blockEnd: '%>',
        variableStart: '<%=',
        variableEnd: '%>',
        commentStart: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final template =
          env.fromString('''<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');

      expect(template.render(seq: range(5)), equals('    01234'));
    });

    test('comment syntax', () {
      final env = Environment(
        blockStart: '<!--',
        blockEnd: '-->',
        variableStart: r'${',
        variableEnd: '}',
        commentStart: '<!--#',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final template =
          env.fromString(r'''<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(template.render(seq: range(5)), equals('01234'));
    });
  });
}
