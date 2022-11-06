import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:string_scanner/string_scanner.dart';

part 'token.dart';

const Map<String, String> operators = <String, String>{
  '-': 'sub',
  ',': 'comma',
  ';': 'semicolon',
  ':': 'colon',
  '!=': 'ne',
  '.': 'dot',
  '(': 'lparen',
  ')': 'rparen',
  '[': 'lbracket',
  ']': 'rbracket',
  '{': 'lbrace',
  '}': 'rbrace',
  '*': 'mul',
  '**': 'pow',
  '/': 'div',
  '//': 'floordiv',
  '%': 'mod',
  '+': 'add',
  '<': 'lt',
  '<=': 'lteq',
  '=': 'assign',
  '==': 'eq',
  '>': 'gt',
  '>=': 'gteq',
  '|': 'pipe',
  '~': 'tilde',
};

const List<String> ignoredTokens = <String>[
  'whitespace',
  'comment_start',
  'comment',
  'comment_end',
  'raw_start',
  'raw_end',
  'linecomment_start',
  'linecomment_end',
  'linecomment',
];

const List<String> ignoreIfEmpty = <String>[
  'whitespace',
  'data',
  'comment',
  'linecomment',
];

String escapeRe(String pattern) {
  return RegExp.escape(pattern);
}

RegExp compileRe(String pattern) {
  return RegExp(pattern, dotAll: true, multiLine: true);
}

abstract class Rule {
  Rule(this.regExp, [this.newState]);

  final RegExp regExp;

  final String? newState;

  @override
  String toString() {
    return 'Rule($newState)';
  }
}

class SingleTokenRule extends Rule {
  SingleTokenRule(super.regExp, this.token, [super.newState]);

  final String token;

  @override
  String toString() {
    return 'SingleTokenRule($token, $newState)';
  }
}

class MultiTokenRule extends Rule {
  MultiTokenRule(super.regExp, this.tokens, [super.newState])
      : optionalLStrip = false;

  MultiTokenRule.optionalLStrip(super.regExp, this.tokens, [super.newState])
      : optionalLStrip = true;

  final List<String> tokens;

  final bool optionalLStrip;

  @override
  String toString() {
    return 'MultiTokenRule($tokens, $optionalLStrip, $newState)';
  }
}

class Lexer {
  Lexer(Environment environment)
      : newLineRe = RegExp('(\r\n|\r|\n)'),
        whitespaceRe = RegExp('\\s+'),
        nameRe = RegExp('[a-zA-Z\$_][a-zA-Z0-9\$_]*'),
        stringRe = RegExp(
            '(\'([^\'\\\\]*(?:\\\\.[^\'\\\\]*)*)\'|"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)")',
            dotAll: true),
        integerRe = RegExp('(0[xX](_?[\\da-fA-F])+|\\d(_?\\d)*)'),
        floatRe = RegExp(
            '(?<!\\.)(\\d+_)*\\d+((\\.(\\d+_)*\\d+)?[eE][+\\-]?(\\d+_)*\\d+|\\.(\\d+_)*\\d+)'),
        operatorRe = RegExp(
            '\\+|-|\\/\\/|\\/|\\*\\*|\\*|%|~|\\[|\\]|\\(|\\)|{|}|==|!=|<=|>=|=|<|>|\\.|:|\\||,|;'),
        leftStripUnlessRe =
            environment.leftStripBlocks ? compileRe('[^ \\t]') : null,
        newLine = environment.newLine,
        keepTrailingNewLine = environment.keepTrailingNewLine {
    var blockSuffixRe = environment.trimBlocks ? r'\n?' : '';

    var commentStartRe = escapeRe(environment.commentStart);
    var commentEndRe = escapeRe(environment.commentEnd);
    var commentEnd = compileRe(
        '(.*?)((?:\\+$commentEndRe|-$commentEndRe\\s*|$commentEndRe$blockSuffixRe))');

    var variableStartRe = escapeRe(environment.variableStart);
    var variableEndRe = escapeRe(environment.variableEnd);
    var variableEnd = compileRe('-$variableEndRe\\s*|$variableEndRe');

    var blockStartRe = escapeRe(environment.blockStart);
    var blockEndRe = escapeRe(environment.blockEnd);
    var blockEnd = compileRe(
        '(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe)');

    var tagRules = <Rule>[
      SingleTokenRule(whitespaceRe, 'whitespace'),
      SingleTokenRule(floatRe, 'float'),
      SingleTokenRule(integerRe, 'integer'),
      SingleTokenRule(nameRe, 'name'),
      SingleTokenRule(stringRe, 'string'),
      SingleTokenRule(operatorRe, 'operator'),
    ];

    var rootTagRules = <List<String>>[
      <String>['comment_start', environment.commentStart, commentStartRe],
      <String>['variable_start', environment.variableStart, variableStartRe],
      <String>['block_start', environment.blockStart, blockStartRe],
      if (environment.lineCommentPrefix != null)
        <String>[
          'linecomment_start',
          environment.lineCommentPrefix!,
          '(?:^|(?<=\\S))[^\\S\r\n]*${environment.lineCommentPrefix!}'
        ],
      if (environment.lineStatementPrefix != null)
        <String>[
          'linestatement_start',
          environment.lineStatementPrefix!,
          '^[ \t\v]*${environment.lineStatementPrefix!}'
        ],
    ];

    rootTagRules.sort((a, b) => b[1].length.compareTo(a[1].length));

    var rawStart = compileRe(
        '(?<raw_start>$blockStartRe(-|\\+|)\\s*raw\\s*(?:-$blockEndRe\\s*|$blockEndRe))');
    var rawEnd = compileRe('(.*?)((?:$blockStartRe(-|\\+|))\\s*endraw\\s*'
        '(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe))');

    var rootParts = <String>[
      rawStart.pattern,
      for (var rule in rootTagRules) '(?<${rule.first}>${rule.last}(-|\\+|))',
    ];

    var rootPartsRe = rootParts.join('|');
    var data = compileRe('(.*?)(?:$rootPartsRe)');

    rules = <String, List<Rule>>{
      'root': <Rule>[
        MultiTokenRule.optionalLStrip(
          data,
          <String>['data', '#group'],
          '#group',
        ),
        SingleTokenRule(
          compileRe('.+'),
          'data',
        ),
      ],
      'comment_start': <Rule>[
        MultiTokenRule(
          commentEnd,
          <String>['comment', 'comment_end'],
          '#pop',
        ),
        MultiTokenRule(
          compileRe('(.)'),
          <String>['@missing end of comment tag'],
        ),
      ],
      'variable_start': <Rule>[
        SingleTokenRule(
          variableEnd,
          'variable_end',
          '#pop',
        ),
        ...tagRules,
      ],
      'block_start': <Rule>[
        SingleTokenRule(
          blockEnd,
          'block_end',
          '#pop',
        ),
        ...tagRules,
      ],
      'raw_start': <Rule>[
        MultiTokenRule.optionalLStrip(
          rawEnd,
          <String>['data', 'raw_end'],
          '#pop',
        ),
        MultiTokenRule(
          compileRe('(.)'),
          <String>['@missing end of raw directive'],
        ),
      ],
      if (environment.lineCommentPrefix != null)
        'linecomment_start': <Rule>[
          MultiTokenRule(
            compileRe('(.*?)()(?=\n|\$)'),
            <String>['linecomment', 'linecomment_end'],
            '#pop',
          ),
        ],
      if (environment.lineStatementPrefix != null)
        'linestatement_start': <Rule>[
          SingleTokenRule(
            compileRe('\\s*(\n|\$)'),
            'linestatement_end',
            '#pop',
          ),
          ...tagRules,
        ],
    };
  }

  final RegExp newLineRe;

  final RegExp whitespaceRe;

  final RegExp nameRe;

  final RegExp stringRe;

  final RegExp integerRe;

  final RegExp floatRe;

  final RegExp operatorRe;

  final RegExp? leftStripUnlessRe;

  final String newLine;

  final bool keepTrailingNewLine;

  late Map<String, List<Rule>> rules;

  String normalizeNewLines(String value) {
    return value.replaceAll(newLineRe, newLine);
  }

  List<Token> scan(StringScanner scanner, [String? state]) {
    const endTokens = <String>[
      'variable_end',
      'block_end',
      'linestatement_end'
    ];

    var stack = <String>['root'];
    var balancingStack = <String>[];

    if (state != null && state != 'root') {
      assert(state == 'variable' || state == 'block');
      stack.add('${state}_start');
    }

    var stateRules = rules[stack.last]!;
    var position = 0;
    var line = 1;
    var newLinesStripped = 0;
    var lineStarting = true;

    var tokens = <Token>[];

    while (true) {
      var notBreak = true;

      for (var rule in stateRules) {
        if (!scanner.scan(rule.regExp)) {
          continue;
        }

        var match = scanner.lastMatch as RegExpMatch;

        if (rule is MultiTokenRule) {
          var indexes = List<int>.generate(match.groupCount, (i) => i + 1);
          var groups = match.groups(indexes);

          if (rule.optionalLStrip) {
            var text = groups[0]!;
            String? stripSign;

            for (var i = 2; i < groups.length; i += 2) {
              if (groups[i] != null) {
                stripSign = groups[i]!;
              }
            }

            if (stripSign == '-') {
              var stripped = text.trimRight();
              var substring = text.substring(stripped.length);
              newLinesStripped = 0;

              for (var char in substring.split('')) {
                if (char == '\n') {
                  newLinesStripped += 1;
                }
              }

              groups[0] = stripped;
            } else if (stripSign != '+' &&
                leftStripUnlessRe != null &&
                (!match.groupNames.contains('variable_start') ||
                    match.namedGroup('variable_start') == null)) {
              var lastPosition = text.lastIndexOf('\n') + 1;

              if (lastPosition > 0 || lineStarting) {
                var index =
                    text.substring(lastPosition).indexOf(leftStripUnlessRe!);

                if (index == -1) {
                  groups[0] = groups[0]!.substring(0, lastPosition);
                }
              }
            }
          }

          for (var i = 0; i < rule.tokens.length; i += 1) {
            var token = rule.tokens[i];

            if (token.startsWith('@')) {
              // TODO: update error message
              throw Exception(token.substring(1));
            } else if (token == '#group') {
              var notFound = true;

              for (var name in match.groupNames) {
                var group = match.namedGroup(name);

                if (group != null) {
                  tokens.add(Token(line, name, group));
                  notFound = false;

                  for (var char in group.split('')) {
                    if (char == '\n') {
                      line += 1;
                    }
                  }
                }
              }

              if (notFound) {
                // TODO: update error message
                throw Exception('${rule.regExp} wanted to resolve the token '
                    'dynamically but no group matched');
              }
            } else {
              var data = groups[i];

              if (data == null) {
                tokens.add(Token.simple(line, token));
              } else {
                if (data.isNotEmpty || !ignoreIfEmpty.contains(token)) {
                  tokens.add(Token(line, token, data));
                }

                for (var char in data.split('')) {
                  if (char == '\n') {
                    line += 1;
                  }
                }

                line += newLinesStripped;
                newLinesStripped = 0;
              }
            }
          }
        } else if (rule is SingleTokenRule) {
          if (balancingStack.isNotEmpty && endTokens.contains(rule.token)) {
            scanner.position = match.start;
            continue;
          }

          var data = match[0];
          var token = rule.token;

          if (token == 'operator') {
            if (data == '(') {
              balancingStack.add(')');
            } else if (data == '[') {
              balancingStack.add(']');
            } else if (data == '{') {
              balancingStack.add('}');
            } else if (data == ')' || data == ']' || data == '}') {
              if (balancingStack.isEmpty) {
                throw TemplateSyntaxError("unexpected '$data'");
              }

              var expected = balancingStack.removeLast();

              if (data != expected) {
                throw TemplateSyntaxError(
                    "unexpected '$data', expected '$expected'");
              }
            }
          }

          if (data == null) {
            tokens.add(Token.simple(line, token));
          } else {
            if (data.isNotEmpty || !ignoreIfEmpty.contains(token)) {
              tokens.add(Token(line, token, data));
            }

            for (var char in data.split('')) {
              if (char == '\n') {
                line += 1;
              }
            }
          }
        } else {
          throw UnsupportedError('${rule.runtimeType}');
        }

        var position2 = match.end;
        lineStarting = match[0]!.endsWith('\n');

        if (rule.newState != null) {
          if (rule.newState == '#pop') {
            stack.removeLast();
          } else if (rule.newState == '#group') {
            var notFound = true;

            for (var name in match.groupNames) {
              var group = match.namedGroup(name);

              if (group != null) {
                stack.add(name);
                notFound = false;
              }
            }

            if (notFound) {
              // TODO: update error message
              throw Exception('${rule.regExp} wanted to resolve the token '
                  'dynamically but no group matched');
            }
          } else {
            stack.add(rule.newState!);
          }

          stateRules = rules[stack.last]!;
        } else if (position == position2) {
          // TODO: update error message
          throw Exception(
              '${rule.regExp} yielded empty string without stack change');
        }

        position = position2;
        notBreak = false;
        break;
      }

      if (notBreak) {
        if (scanner.isDone) {
          return tokens;
        } else {
          throw TemplateSyntaxError(
              'unexpected char ${scanner.rest[0]} at ${scanner.position}.');
        }
      }
    }
  }

  List<Token> tokenize(String source, {String? path}) {
    var lines = split(newLineRe, source);

    if (!keepTrailingNewLine && lines.last.isEmpty) {
      lines.removeLast();
    }

    source = lines.join('\n');
    var scanner = StringScanner(source, sourceUrl: path);
    var tokens = <Token>[];

    for (var token in scan(scanner)) {
      if (ignoredTokens.any(token.test)) {
        continue;
      } else if (token.test('linestatement_start')) {
        tokens.add(token.change(type: 'block_start'));
      } else if (token.test('linestatement_end')) {
        tokens.add(token.change(type: 'block_end'));
      } else if (token.test('data')) {
        tokens.add(token.change(value: normalizeNewLines(token.value)));
      } else if (token.test('string')) {
        var value = token.value;
        value = normalizeNewLines(value.substring(1, value.length - 1));
        tokens.add(token.change(value: value));
      } else if (token.test('integer') || token.test('float')) {
        tokens.add(token.change(value: token.value.replaceAll('_', '')));
      } else if (token.test('operator')) {
        tokens.add(Token.simple(token.line, operators[token.value]!));
      } else {
        tokens.add(token);
      }
    }

    tokens.add(Token.simple(source.length, 'eof'));
    return tokens;
  }

  @override
  String toString() {
    return 'Tokenizer()';
  }

  static List<String> split(Pattern pattern, String text) {
    var matches = pattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return <String>[text];
    }

    var result = <String>[];
    var length = matches.length;
    Match? match;

    for (var i = 0, start = 0; i < length; i += 1, start = match.end) {
      match = matches[i];
      result.add(text.substring(start, match.start));
    }

    if (match != null) {
      result.add(text.substring(match.end));
    }

    return result;
  }
}
