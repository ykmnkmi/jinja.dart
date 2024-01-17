@TestOn('vm || chrome')
library;

import 'package:jinja/jinja.dart';
import 'package:jinja/src/lexer.dart';
import 'package:jinja/src/reader.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

void main() {
  var env = Environment();

  group('TokenReader', () {
    var testTokens = [Token(1, 'block_begin', ''), Token(2, 'block_end', '')];

    test('simple', () {
      var reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
    });

    test('iter', () {
      var reader = TokenReader(testTokens);
      expect([for (var token in reader.values) token.type],
          orderedEquals(<String>['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    const seq = {
      'seq': [0, 1, 2]
    };

    test('raw', () {
      var tmpl = env.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(tmpl.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      var tmpl = env.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(tmpl.render(), equals('123'));
    });

    test('raw3', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env
          .fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(tmpl.render({'baz': 'test'}),
          equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString(
          'bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(tmpl.render(), equals('bar2 spaces\n spacefoo'));
    });

    test('balancing', () {
      var env = Environment(
          blockStart: '{%',
          blockEnd: '%}',
          variableStart: r'${',
          variableEnd: '}');
      var tmpl = env.fromString(r'''{% for item in seq
            %}${{'foo': item}|string|upper}{% endfor %}''');
      expect(tmpl.render(seq), equals('{FOO: 0}{FOO: 1}{FOO: 2}'));
    });

    test('comments', () {
      var env = Environment(
          blockStart: '<!--',
          blockEnd: '-->',
          variableStart: '{',
          variableEnd: '}');
      var tmpl = env.fromString('''
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>''');
      expect(tmpl.render(seq),
          equals('<ul>\n  <li>0</li>\n  <li>1</li>\n  <li>2</li>\n</ul>'));
    });

    // not supported
    // test('bytefallback', () {
    //   var environment = Environment();
    //   var template = environment.fromString('{{ \'foo\'|pprint }}|{{ \'bär\'|pprint }}');
    //   expect(template.render(), equals(pformat('foo') + '|' + pformat('bär')));
    // });

    test('operators', () {
      operators.forEach((test, expekt) {
        if ('([{}])'.contains(test)) {
          return;
        }

        var tokens = Lexer(env).tokenize('{{ $test }}');

        bool predication(Token token) {
          return token.test(expekt);
        }

        expect(tokens.elementAt(1), equals(predicate<Token>(predication)));
      });
    });

    test('normalizing', () {
      for (var newLine in ['\r', '\r\n', '\n']) {
        var env = Environment(newLine: newLine);
        var tmpl = env.fromString('1\n2\r\n3\n4\n');
        expect(tmpl.render().replaceAll(newLine, 'X'), equals('1X2X3X4'));
      }
    });

    test('trailing newline', () {
      var env = Environment(keepTrailingNewLine: true);
      var tmpl = env.fromString('');
      expect(tmpl.render(), equals(''));
      tmpl = env.fromString('no\nnewline');
      expect(tmpl.render(), equals('no\nnewline'));
      tmpl = env.fromString('with\nnewline\n');
      expect(tmpl.render(), equals('with\nnewline\n'));
      tmpl = env.fromString('with\nseveral\n\n\n');
      expect(tmpl.render(), equals('with\nseveral\n\n\n'));
      env = Environment(keepTrailingNewLine: false);
      expect(env.fromString('').render(), equals(''));
      tmpl = env.fromString('no\nnewline');
      expect(tmpl.render(), equals('no\nnewline'));
      tmpl = env.fromString('with\nnewline\n');
      expect(tmpl.render(), equals('with\nnewline'));
      tmpl = env.fromString('with\nseveral\n\n\n');
      expect(tmpl.render(), equals('with\nseveral\n\n'));
    });

    test('name', () {
      expect(env.fromString('{{ foo }}'), isA<Template>());
      expect(env.fromString('{{ _ }}'), isA<Template>());
      var matcher = throwsA(isA<TemplateSyntaxError>());
      // invalid ascii start
      expect(() => env.fromString('{{ 1a }}'), matcher);
      // invalid ascii continue
      expect(() => env.fromString('{{ a- }}'), matcher);
    });

    test('lineno with strip', () {
      var tokens = env.lex('''
<html>
    <body>
    {%- block content -%}
        <hr>
        {{ item }}
    {% endblock %}
    </body>
</html>''');

      for (var token in tokens) {
        if (token.test('name', 'item')) {
          expect(token.line, equals(5));
          break;
        }
      }
    });

    // TODO: add test: string escapes
  });

  group('LStripBlocks', () {
    const kvs = [
      ['a', 1],
      ['b', 2]
    ];

    test('lstrip', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('    {% if true %}\n    {% endif %}');
      expect(tmpl.render(), equals('\n'));
    });

    test('lstrip trim', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('  {% if true %}\n  {% endif %}');
      expect(tmpl.render(), equals(''));
    });

    test('no lstrip', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('lstrip blocks false with no lstrip', () {
      var env = Environment(leftStripBlocks: false, trimBlocks: false);
      var tmpl = env.fromString('    {% if true %}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {%+ if true %}\n    {%+ endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('lstrip endline', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('  hello{% if true %}\n  goodbye{% endif %}');
      expect(tmpl.render(), equals('  hello\n  goodbye'));
    });

    test('lstrip inline', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('    {% if true %}hello    {% endif %}');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip nested', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString(
          '    {% if true %}a {% if true %}b {% endif %}c {% endif %}');
      expect(tmpl.render(), equals('a b c '));
    });

    test('lstrip left chars', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('''    abc {% if true %}
        hello{% endif %}''');
      expect(tmpl.render(), equals('    abc \n        hello'));
    });

    test('lstrip embeded strings', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('    {% set x = " {% str %} " %}{{ x }}');
      expect(tmpl.render(), equals(' {% str %} '));
    });

    test('lstrip preserve leading newlines', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('\n\n\n{% set hello = 1 %}');
      expect(tmpl.render(), equals('\n\n\n'));
    });

    test('lstrip comment', () {
      var env = Environment(leftStripBlocks: true);
      var tmpl = env.fromString('''    {# if true #}
hello
    {#endif#}''');
      expect(tmpl.render(), equals('\nhello\n'));
    });

    test('lstrip angle bracket simple', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('    <% if true %>hello    <% endif %>');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip angle bracket comment', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('    <%# if true %>hello    <%# endif %>');
      expect(tmpl.render(), equals('hello    '));
    });

    test('lstrip angle bracket', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString(r'''
    <%# regular comment %>
    <% for item in seq %>
${item} ## the rest of the stuff
   <% endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('0\n1\n2\n3\n4\n'));
    });

    test('lstrip angle bracket compact', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          lineCommentPrefix: '##',
          lineStatementPrefix: '%',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString(r'''
    <%#regular comment%>
    <%for item in seq%>
${item} ## the rest of the stuff
   <%endfor%>''');
      expect(tmpl.render({'seq': range(5)}), equals('0\n1\n2\n3\n4\n'));
    });

    test('lstrip blocks outside with new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(tmpl.render({'kvs': kvs}), equals('(\na=1 b=2 \n  )'));
    });

    test('lstrip trim blocks outside with new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('  {% if kvs %}(\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  ){% endif %}');
      expect(tmpl.render({'kvs': kvs}), equals('(\na=1 b=2   )'));
    });

    test('lstrip blocks inside with new line', () {
      var env = Environment(leftStripBlocks: true);
      var tmpl = env.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(tmpl.render({'kvs': kvs}), equals('  (\na=1 b=2 \n)'));
    });

    test('lstrip trim blocks inside with new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('  ({% if kvs %}\n'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}\n'
          '  {% endif %})');
      expect(tmpl.render({'kvs': kvs}), equals('  (a=1 b=2 )'));
    });

    test('lstrip blocks without new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(tmpl.render({'kvs': kvs}), equals('   a=1 b=2   '));
    });

    test('lstrip trim blocks without new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('  {% if kvs %}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor %}'
          '  {% endif %}');
      expect(tmpl.render({'kvs': kvs}), equals('   a=1 b=2   '));
    });

    test('lstrip blocks consume after without new line', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: false);
      var tmpl = env.fromString('  {% if kvs -%}'
          '   {% for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {% endif -%}');
      expect(tmpl.render({'kvs': kvs}), equals('a=1 b=2 '));
    });

    test('lstrip trim blocks consume before without new line', () {
      var env = Environment(leftStripBlocks: false, trimBlocks: false);
      var tmpl = env.fromString('  {%- if kvs %}'
          '   {%- for k, v in kvs %}{{ k }}={{ v }} {% endfor -%}'
          '  {%- endif %}');
      expect(tmpl.render({'kvs': kvs}), equals('a=1 b=2 '));
    });

    test('lstrip trim blocks comment', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl =
          env.fromString(' {# 1 space #}\n  {# 2 spaces #}    {# 4 spaces #}');
      expect(tmpl.render(), equals('    '));
    });

    test('lstrip trim blocks raw', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('{{x}}\n{%- raw %} {% endraw -%}\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1 2'));
    });

    test('php syntax with manual', () {
      var env = Environment(
          blockStart: '<?',
          blockEnd: '?>',
          variableStart: '<?=',
          variableEnd: '?>',
          commentStart: '<!--',
          commentEnd: '-->',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('php syntax', () {
      var env = Environment(
          blockStart: '<?',
          blockEnd: '?>',
          variableStart: '<?=',
          variableEnd: '?>',
          commentStart: '<!--',
          commentEnd: '-->',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (var i in range(5)) '        $i\n'].join()));
    });

    test('php syntax compact', () {
      var env = Environment(
          blockStart: '<?',
          blockEnd: '?>',
          variableStart: '<?=',
          variableEnd: '?>',
          commentStart: '<!--',
          commentEnd: '-->',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (var i in range(5)) '        $i\n'].join()));
    });

    test('erb syntax', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: '<%=',
          variableEnd: '%>',
          commentStart: '<%#',
          commentEnd: '%>',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
  <% for item in seq %>
  <%= item %>
  <% endfor %>
''');
      expect(tmpl.render({'seq': range(5)}),
          equals([for (var i in range(5)) '  $i\n'].join()));
    });

    test('erb syntax with manual', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: '<%=',
          variableEnd: '%>',
          commentStart: '<%#',
          commentEnd: '%>',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });

    test('erb syntax no lstrip', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: '<%=',
          variableEnd: '%>',
          commentStart: '<%#',
          commentEnd: '%>',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('''
<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>''');
      expect(tmpl.render({'seq': range(5)}), equals('    01234'));
    });

    test('comment syntax', () {
      var env = Environment(
          blockStart: '<!--',
          blockEnd: '-->',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<!--#',
          commentEnd: '-->',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString(r'''
<!--# I'm a comment, I'm not interesting --><!-- for item in seq --->
    ${item}
<!--- endfor -->''');
      expect(tmpl.render({'seq': range(5)}), equals('01234'));
    });
  });

  group('TrimBlocks', () {
    test('trim', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('    {% if true %}\n    {% endif %}');
      expect(tmpl.render(), equals('        '));
    });

    test('no trim', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('    {% if true +%}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
    });

    test('no trim outer', () {
      var env = Environment(trimBlocks: true);
      var tmpl = env.fromString('{% if true %}X{% endif +%}\nmore things');
      expect(tmpl.render(), equals('X\nmore things'));
    });

    test('lstrip no trim', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('    {% if true +%}\n    {% endif %}');
      expect(tmpl.render(), equals('\n'));
    });

    test('trim blocks false with no trim', () {
      var env = Environment(leftStripBlocks: false, trimBlocks: false);
      var tmpl = env.fromString('    {% if true %}\n    {% endif %}');
      expect(tmpl.render(), equals('    \n    '));
      tmpl = env.fromString('    {% if true +%}\n    {% endif %}');
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
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString(
          '    {% if true %}\na {% if true %}\nb {% endif %}\nc {% endif %}');
      expect(tmpl.render(), equals('a b c '));
    });

    test('no trim nested', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString(
          '    {% if true +%}\na {% if true +%}\nb {% endif +%}\nc {% endif %}');
      expect(tmpl.render(), equals('\na \nb \nc '));
    });

    test('comment trim', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('    {# comment #}\n\n  ');
      expect(tmpl.render(), equals('\n  '));
    });

    test('comment no trim', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('    {# comment +#}\n\n  ');
      expect(tmpl.render(), equals('\n\n  '));
    });

    test('multiple comment trim lstrip', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString(
          '   {# comment #}\n\n{# comment2 #}\n   \n{# comment3 #}\n\n ');
      expect(tmpl.render(), equals('\n   \n\n '));
    });

    test('multiple comment no trim lstrip', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString(
          '   {# comment +#}\n\n{# comment2 +#}\n   \n{# comment3 +#}\n\n ');
      expect(tmpl.render(), equals('\n\n\n   \n\n\n '));
    });

    test('raw trim lstrip', () {
      var env = Environment(leftStripBlocks: true, trimBlocks: true);
      var tmpl = env.fromString('{{x}}{% raw %}\n\n   {% endraw %}\n\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1\n\n\n2'));
    });

    test('raw no trim lstrip', () {
      var env = Environment(leftStripBlocks: true);
      var tmpl =
          env.fromString('{{x}}{% raw %}\n\n    {% endraw %}\n\n{{ y }}');
      expect(tmpl.render({'x': 1, 'y': 2}), equals('1\n\n\n\n2'));
    });

    test('no trim angle bracket', () {
      var env = Environment(
          blockStart: '<%',
          blockEnd: '%>',
          variableStart: r'${',
          variableEnd: '}',
          commentStart: '<%#',
          commentEnd: '%>',
          leftStripBlocks: true,
          trimBlocks: true);
      var tmpl = env.fromString('    <% if true +%>\n\n    <% endif %>');
      expect(tmpl.render(), equals('\n\n'));
      tmpl = env.fromString('    <%# comment +%>\n\n   ');
      expect(tmpl.render(), equals('\n\n   '));
    });

    test('no trim php syntax', () {
      var env = Environment(
          blockStart: '<?',
          blockEnd: '?>',
          variableStart: '<?=',
          variableEnd: '?>',
          commentStart: '<!--',
          commentEnd: '-->',
          trimBlocks: true);
      var tmpl = env.fromString('    <? if true +?>\n\n    <? endif ?>');
      expect(tmpl.render(), equals('    \n\n    '));
      tmpl = env.fromString('    <!-- comment +-->\n\n    ');
      expect(tmpl.render(), equals('    \n\n    '));
    });
  });
}
