import 'package:jinja/ast.dart';
import 'package:jinja/jinja.dart';
import 'package:jinja/runtime.dart' hide isTrue;
import 'package:test/test.dart';

import 'environment.dart';

void main() {
  group('TokenReader', () {
    late final testTokens = [
      Token(1, 'block_begin', ''),
      Token(2, 'block_end', '')
    ];

    test('simple', () {
      final reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
    });

    test('iter', () {
      final reader = TokenReader(testTokens);
      expect([for (final token in reader.values) token.type],
          orderedEquals(<String>['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    late final seq123 = {
      'seq': [0, 1, 2]
    };

    test('raw', () {
      final tmpl = parse('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(tmpl.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final tmpl = parse('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(tmpl.render(), equals('123'));
    });

    test('raw3', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env
          .fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(tmpl.render({'baz': 'test'}),
          equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString(
          'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(tmpl.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      final env = Environment(
        blockBegin: '{%',
        blockEnd: '%}',
        variableBegin: r'${',
        variableEnd: '}',
      );
      final tmpl = env.fromString(r'''{% for item in seq
            %}${{'foo': item} | upper}{% endfor %}''');
      expect(tmpl.render(seq123), equals('{FOO: 0}{FOO: 1}{FOO: 2}'));
    });

    test('comments', () {
      final env = Environment(
        blockBegin: '<!--',
        blockEnd: '-->',
        variableBegin: '{',
        variableEnd: '}',
      );
      final tmpl = env.fromString('''
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(tmpl.render(seq123),
          equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    test('string escapes', () {
      var tmpl = parse('{{ ${represent('\t')} }}');
      expect(tmpl.render(), equals('\t'));
      tmpl = parse('{{ ${represent('\r')} }}');
      expect(tmpl.render(), equals('\r'));
      tmpl = parse('{{ ${represent('\n')} }}');
      expect(tmpl.render(), equals('\n'));
    });

    // not supported
    // test('bytefallback', () {
    //   final environment = Environment();
    //   final template = environment.fromString('{{ \'foo\' | pprint }}|{{ \'bär\' | pprint }}');
    //   expect(template.render(), equals(pformat('foo') + '|' + pformat('bär')));
    // });

    test('operators', () {
      operators.forEach((test, expekt) {
        if ('([{}])'.contains(test)) {
          return;
        }

        final tokens = Lexer(environment).tokenize('{{ $test }}');
        expect(
            tokens[1], equals(predicate<Token>((token) => token.test(expekt))));
      });
    });

    test('normalizing', () {
      for (final newLine in ['\r', '\r\n', '\n']) {
        expect(
            Environment(newLine: newLine)
                .fromString('1\n2\r\n3\n4\n')
                .render()
                .replaceAll(newLine, 'X'),
            equals('1X2X3X4'));
      }
    });

    test('trailing newline', () {
      var environment = Environment(keepTrailingNewLine: true);

      expect(environment.fromString('').render(), equals(''));
      expect(environment.fromString('no\nnewline').render(),
          equals('no\nnewline'));
      expect(environment.fromString('with\nnewline\n').render(),
          equals('with\nnewline\n'));
      expect(environment.fromString('with\nseveral\n\n\n').render(),
          equals('with\nseveral\n\n\n'));

      environment = Environment(keepTrailingNewLine: false);
      expect(environment.fromString('').render(), equals(''));
      expect(environment.fromString('no\nnewline').render(),
          equals('no\nnewline'));
      expect(environment.fromString('with\nnewline\n').render(),
          equals('with\nnewline'));
      expect(environment.fromString('with\nseveral\n\n\n').render(),
          equals('with\nseveral\n\n'));
    });

    test('name', () {
      expect(parse('{{ foo }}'), isA<Template>());
      expect(parse('{{ _ }}'), isA<Template>());
      // invalid ascii start
      expect(() => parse('{{ 1a }}'), throwsA(isA<TemplateSyntaxError>()));
      // invalid ascii continue
      expect(() => parse('{{ a- }}'), throwsA(isA<TemplateSyntaxError>()));
    });

    test('lineno with strip', () {
      final tokens = Lexer(environment)
          .tokenize('<html>\n    <body>\n    {%- block content -%}\n'
              '        <hr>\n        {{ item }}\n    {% endblock %}\n'
              '    </body>\n</html>');

      for (final token in tokens) {
        if (token.test('name', 'item')) {
          expect(token.line, equals(5));
        }
      }
    });
  });

  group('LStripBlocks', () {
    late final kvs = {
      'kvs': [
        ['a', 1],
        ['b', 2]
      ]
    };

    test('lstrip', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('    {% if True %}\n    {% endif %}');
      expect(tmpl.render(), equals('\n'));
    });

    test('lstrip trim', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('  {% if true %}\n  {% endif %}');
      expect(tmpl.render(), equals(''));
    });

    test('no lstrip', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      final env = Environment(leftStripBlocks: false, trimBlocks: false);
      var tmpl = env.fromString('    {% if True %}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {%+ if True %}\n    {%+ endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('lstrip endline', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl =
          env.fromString('    hello{% if True %}\n    goodbye{% endif %}');
      expect(tmpl.render(), equals('    hello\n    goodbye'));
    });

    test('lstrip inline', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('    {% if True %}hello    {% endif %}');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip nested', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString(
          '    {% if True %}a {% if True %}b {% endif %}c {% endif %}');
      expect(tmpl.render(), equals('a b c '));
    });

    test('lstrip left chars', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('''    abc {% if True %}
        hello{% endif %}''');
      expect(tmpl.render(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(tmpl.render(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('\n\n\n{% set hello = 1 %}');
      expect(tmpl.render(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      final env = Environment(leftStripBlocks: true);
      final tmpl = env.fromString('''    {# if True #}
hello
    {#endif#}''');
      expect(tmpl.render(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('    <% if True %>hello    <% endif %>');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('    <%# if True %>hello    <%# endif %>');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip angle bracket', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString(r'''
    <%# regular comment %>
    <% for item in seq %>
${item} ## the rest of the stuff
   <% endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('0\n1\n2\n3\n4\n'));
    });

    test('lstrip angle bracket compact', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        lineCommentPrefix: '##',
        lineStatementPrefix: '%',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString(r'''
    <%#regular comment%>
    <%for item in seq%>
${item} ## the rest of the stuff
   <%endfor%>''');
      expect(tmpl.render({'seq': range(5)}), equals('0\n1\n2\n3\n4\n'));
    });

    test('lstrip blocks outside with new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(tmpl.render(kvs), equals('(\na=1 b=2 \n  )'));
    });

    test('lstrip trim blocks outside with new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(tmpl.render(kvs), equals('(\na=1 b=2   )'));
    });

    test('lstrip blocks inside with new line', () {
      final env = Environment(leftStripBlocks: true);
      final tmpl = env.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(tmpl.render(kvs), equals('  (\na=1 b=2 \n)'));
    });

    test('lstrip trim blocks inside with new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(tmpl.render(kvs), equals('  (a=1 b=2 )'));
    });

    test('lstrip blocks without new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      final tmpl = env.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(tmpl.render(kvs), equals('   a=1 b=2   '));
    });

    test('lstrip trim blocks without new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(tmpl.render(kvs), equals('   a=1 b=2   '));
    });

    test('lstrip blocks consume after without new line', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('  {% if kvs -%}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {% endif -%}');
      expect(tmpl.render(kvs), equals('a=1 b=2 '));
    });

    test('lstrip trim blocks consume before without new line', () {
      final env = Environment(leftStripBlocks: false, trimBlocks: false);
      final tmpl = env.fromString('  {%- if kvs %}'
          '   {%- for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {%- endif %}');
      expect(tmpl.render(kvs), equals('a=1 b=2 '));
    });

    test('lstrip trim blocks comment', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl =
          env.fromString(' {# 1 space #}\n  {# 2 spaces #}    {# 4 spaces #}');
      expect(tmpl.render(), equals('    '));
    });

    test('lstrip trim blocks raw', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('{{x}}\n{%- raw %} {% endraw -%}\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1 2'));
    });

    test('php syntax with manual', () {
      final env = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: '<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('php syntax', () {
      final env = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: '<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (final i in range(5)) '        $i\n'].join()));
    });

    test('php syntax compact', () {
      final env = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: '<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (final i in range(5)) '        $i\n'].join()));
    });

    test('erb syntax', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '<%=',
        variableEnd: '%>',
        commentBegin: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (final i in range(5)) '    $i\n'].join()));
    });

    test('erb syntax with manual', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '<%=',
        variableEnd: '%>',
        commentBegin: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: '<%=',
        variableEnd: '%>',
        commentBegin: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );
      final tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('    01234'));
    });

    test('comment syntax', () {
      final env = Environment(
        blockBegin: '<!--',
        blockEnd: '-->',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<!--#',
        commentEnd: '-->',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      final tmpl = env.fromString(r'''
<!--# I'm a comment, I'm not interesting --><!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });
  });

  group('TrimBlocks', () {
    test('trim', () {
      final env = Environment(trimBlocks: true);
      final tmpl = env.fromString('    {% if True %}\n    {% endif %}');
      expect(tmpl.render(), equals('        '));
    });

    test('no trim', () {
      final env = Environment(trimBlocks: true);
      final tmpl = env.fromString('    {% if True +%}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('no trim outer', () {
      final env = Environment(trimBlocks: true);
      final tmpl = env.fromString('{% if True %}X{% endif +%}\nmore things');
      expect(tmpl.render(), equals('X\nmore things'));
    });

    test('lstrip no trim', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('    {% if True +%}\n    {% endif %}');
      expect(tmpl.render(), equals('\n'));
    });

    test('trim blocks false with no trim', () {
      final env = Environment(leftStripBlocks: false, trimBlocks: false);
      var tmpl = env.fromString('    {% if True %}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {% if True +%}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));

      tmpl = env.fromString('    {# comment #}\n    ');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {# comment +#}\n    ');
      expect(tmpl.render(), equals('    \n    '));

      tmpl = env.fromString('    {% raw %}{% endraw %}\n    ');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {% raw %}{% endraw +%}\n    ');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('trim nested', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString(
          '    {% if True %}\na {% if True %}\nb {% endif %}\nc {% endif %}');
      expect(tmpl.render(), equals('a b c '));
    });

    test('no trim nested', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString(
          '    {% if True +%}\na {% if True +%}\nb {% endif +%}\nc {% endif %}');
      expect(tmpl.render(), equals('\na \nb \nc '));
    });

    test('comment trim', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('    {# comment #}\n\n  ');
      expect(tmpl.render(), equals('\n  '));
    });

    test('comment no trim', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString('    {# comment +#}\n\n  ');
      expect(tmpl.render(), equals('\n\n  '));
    });

    test('multiple comment trim lstrip', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString(
          '   {# comment #}\n\n{# comment2 #}\n   \n{# comment3 #}\n\n ');
      expect(tmpl.render(), equals('\n   \n\n '));
    });

    test('multiple comment no trim lstrip', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl = env.fromString(
          '   {# comment +#}\n\n{# comment2 +#}\n   \n{# comment3 +#}\n\n ');
      expect(tmpl.render(), equals('\n\n\n   \n\n\n '));
    });

    test('raw trim lstrip', () {
      final env = Environment(leftStripBlocks: true, trimBlocks: true);
      final tmpl =
          env.fromString('{{x}}{% raw %}\n\n   {% endraw %}\n\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1\n\n\n2'));
    });

    test('raw no trim lstrip', () {
      final env = Environment(leftStripBlocks: true);
      final tmpl =
          env.fromString('{{x}}{% raw %}\n\n    {% endraw %}\n\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1\n\n\n\n2'));
    });

    test('no trim angle bracket', () {
      final env = Environment(
        blockBegin: '<%',
        blockEnd: '%>',
        variableBegin: r'${',
        variableEnd: '}',
        commentBegin: '<%#',
        commentEnd: '%>',
        leftStripBlocks: true,
        trimBlocks: true,
      );

      var tmpl = env.fromString('    <% if True +%>\n\n    <% endif %>');
      expect(tmpl.render(), equals('\n\n'));
      tmpl = env.fromString('    <%# comment +%>\n\n   ');
      expect(tmpl.render(), equals('\n\n   '));
    });

    test('no trim php syntax', () {
      final env = Environment(
        blockBegin: '<?',
        blockEnd: '?>',
        variableBegin: r'<?=',
        variableEnd: '?>',
        commentBegin: '<!--',
        commentEnd: '-->',
        trimBlocks: true,
      );

      var tmpl = env.fromString('    <? if True +?>\n\n    <? endif ?>');
      expect(tmpl.render(), equals('    \n\n    '));
      tmpl = env.fromString('    <!-- comment +-->\n\n    ');
      expect(tmpl.render(), equals('    \n\n    '));
    });
  });
}
