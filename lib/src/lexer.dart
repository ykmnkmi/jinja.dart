library tokenizer;

import 'package:string_scanner/string_scanner.dart';

import 'environment.dart';
import 'exceptions.dart';

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

String escape(String pattern) {
  return RegExp.escape(pattern);
}

RegExp compile(String pattern) {
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
  SingleTokenRule(RegExp regExp, this.token, [String? newState])
      : super(regExp, newState);

  final String token;

  @override
  String toString() {
    return 'SingleTokenRule($token, $newState)';
  }
}

class MultiTokenRule extends Rule {
  MultiTokenRule(RegExp regExp, this.tokens, [String? newState])
      : optionalLStrip = false,
        super(regExp, newState);

  MultiTokenRule.optionalLStrip(RegExp regExp, this.tokens, [String? newState])
      : optionalLStrip = true,
        super(regExp, newState);

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
        nameRe = RegExp('[a-zA-Z\$_][a-zA-Z0-9\$_]*', unicode: true),
        stringRe = RegExp(
            '(\'([^\'\\\\]*(?:\\\\.[^\'\\\\]*)*)\'|"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)")',
            dotAll: true),
        integerRe = RegExp('(\\d+_)*\\d+'),
        floatRe = RegExp(
            '(?<!\\.)(\\d+_)*\\d+((\\.(\\d+_)*\\d+)?e[+\\-]?(\\d+_)*\\d+|\\.(\\d+_)*\\d+)'),
        operatorRe = RegExp(
            '\\+|-|\\/\\/|\\/|\\*\\*|\\*|%|~|\\[|\\]|\\(|\\)|{|}|==|!=|<=|>=|=|<|>|\\.|:|\\||,|;'),
        leftStripUnlessRe =
            environment.leftStripBlocks ? compile('[^ \\t]') : null,
        newLine = environment.newLine,
        keepTrailingNewLine = environment.keepTrailingNewLine {
    final blockSuffixRe = environment.trimBlocks ? r'\n?' : '';

    final commentStartRe = escape(environment.commentStart);
    final commentEndRe = escape(environment.commentEnd);
    final commentEnd = compile(
        '(.*?)((?:\\+$commentEndRe|-$commentEndRe\\s*|$commentEndRe$blockSuffixRe))');

    final variableStartRe = escape(environment.variableStart);
    final variableEndRe = escape(environment.variableEnd);
    final variableEnd = compile('-$variableEndRe\\s*|$variableEndRe');

    final blockStartRe = escape(environment.blockStart);
    final blockEndRe = escape(environment.blockEnd);
    final blockEnd = compile(
        '(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe)');

    final tagRules = <Rule>[
      SingleTokenRule(whitespaceRe, 'whitespace'),
      SingleTokenRule(floatRe, 'float'),
      SingleTokenRule(integerRe, 'integer'),
      SingleTokenRule(nameRe, 'name'),
      SingleTokenRule(stringRe, 'string'),
      SingleTokenRule(operatorRe, 'operator'),
    ];

    final rootTagRules = <List<String>>[
      ['comment_start', environment.commentStart, commentStartRe],
      ['variable_start', environment.variableStart, variableStartRe],
      ['block_start', environment.blockStart, blockStartRe],
      if (environment.lineCommentPrefix != null)
        [
          'linecomment_start',
          environment.lineCommentPrefix!,
          '(?:^|(?<=\\S))[^\\S\r\n]*' + environment.lineCommentPrefix!
        ],
      if (environment.lineStatementPrefix != null)
        [
          'linestatement_start',
          environment.lineStatementPrefix!,
          '^[ \t\v]*' + environment.lineStatementPrefix!
        ],
    ];

    rootTagRules.sort((a, b) => b[1].length.compareTo(a[1].length));

    final rawStart = compile(
        '(?<raw_start>$blockStartRe(-|\\+|)\\s*raw\\s*(?:-$blockEndRe\\s*|$blockEndRe))');
    final rawEnd = compile('(.*?)((?:$blockStartRe(-|\\+|))\\s*endraw\\s*'
        '(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe))');

    final rootParts = <String>[
      rawStart.pattern,
      for (final rule in rootTagRules) '(?<${rule.first}>${rule.last}(-|\\+|))',
    ];

    final rootPartsRe = rootParts.join('|');
    final data = compile('(.*?)(?:$rootPartsRe)');

    rules = <String, List<Rule>>{
      'root': <Rule>[
        MultiTokenRule.optionalLStrip(
          data,
          <String>['data', '#group'],
          '#group',
        ),
        SingleTokenRule(
          compile('.+'),
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
          compile('(.)'),
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
          compile('(.)'),
          <String>['@missing end of raw directive'],
        ),
      ],
      if (environment.lineCommentPrefix != null)
        'linecomment_start': <Rule>[
          MultiTokenRule(
            compile('(.*?)()(?=\n|\$)'),
            <String>['linecomment', 'linecomment_end'],
            '#pop',
          ),
        ],
      if (environment.lineStatementPrefix != null)
        'linestatement_start': <Rule>[
          SingleTokenRule(
            compile('\\s*(\n|\$)'),
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
    const List<String> endTokens = <String>[
      'variable_end',
      'block_end',
      'linestatement_end'
    ];

    final stack = <String>['root'];
    final balancingStack = <String>[];

    if (state != null && state != 'root') {
      assert(state == 'variable' || state == 'block');
      stack.add(state + '_start');
    }

    var stateRules = rules[stack.last]!;
    var position = 0;
    var line = 1;
    var newLinesStripped = 0;
    var lineStarting = true;

    final tokens = <Token>[];

    while (true) {
      var notBreak = true;

      for (final rule in stateRules) {
        if (!scanner.scan(rule.regExp)) {
          continue;
        }

        final match = scanner.lastMatch as RegExpMatch;

        if (rule is MultiTokenRule) {
          final groups = match.groups(
              List<int>.generate(match.groupCount, (index) => index + 1));

          if (rule.optionalLStrip) {
            final text = groups[0]!;
            String? stripSign;

            for (var i = 2; i < groups.length; i += 2) {
              if (groups[i] != null) {
                stripSign = groups[i]!;
              }
            }

            if (stripSign == '-') {
              final stripped = text.trimRight();
              newLinesStripped = text
                  .substring(stripped.length)
                  .split('')
                  .fold<int>(
                      0, (count, char) => char == '\n' ? count + 1 : count);
              groups[0] = stripped;
            } else if (stripSign != '+' &&
                leftStripUnlessRe != null &&
                (!match.groupNames.contains('variable_start') ||
                    match.namedGroup('variable_start') == null)) {
              final lastPosition = text.lastIndexOf('\n') + 1;

              if (lastPosition > 0 || lineStarting) {
                final index =
                    text.substring(lastPosition).indexOf(leftStripUnlessRe!);

                if (index == -1) {
                  groups[0] = groups[0]!.substring(0, lastPosition);
                }
              }
            }
          }

          for (var i = 0; i < rule.tokens.length; i += 1) {
            final token = rule.tokens[i];

            if (token.startsWith('@')) {
              // TODO: update error message
              throw Exception(token.substring(1));
            } else if (token == '#group') {
              var notFound = true;

              for (final name in match.groupNames) {
                final group = match.namedGroup(name);

                if (group != null) {
                  tokens.add(Token(line, name, group));
                  line += group.split('').fold<int>(
                      0, (count, char) => char == '\n' ? count + 1 : count);
                  notFound = false;
                }
              }

              if (notFound) {
                // TODO: update error message
                throw Exception('${rule.regExp} wanted to resolve the token '
                    'dynamically but no group matched');
              }
            } else {
              final data = groups[i];

              if (data == null) {
                tokens.add(Token.simple(line, token));
              } else {
                if (data.isNotEmpty || !ignoreIfEmpty.contains(token)) {
                  tokens.add(Token(line, token, data));
                }

                for (final char in data.split('')) {
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

          final data = match[0];
          final token = rule.token;

          if (token == 'operator') {
            if (data == '(') {
              balancingStack.add(')');
            } else if (data == '[') {
              balancingStack.add(']');
            } else if (data == '{') {
              balancingStack.add('}');
            } else if (data == ')' || data == ']' || data == '}') {
              if (balancingStack.isEmpty) {
                throw TemplateSyntaxError('unexpected \'$data\'');
              }

              final expected = balancingStack.removeLast();

              if (data != expected) {
                throw TemplateSyntaxError(
                    'unexpected \'$data\', expected \'$expected\'');
              }
            }
          }

          if (data == null) {
            tokens.add(Token.simple(line, token));
          } else {
            if (data.isNotEmpty || !ignoreIfEmpty.contains(token)) {
              tokens.add(Token(line, token, data));
            }

            line += data.split('').fold<int>(
                0, (count, char) => char == '\n' ? count + 1 : count);
          }
        } else {
          throw UnsupportedError('${rule.runtimeType}');
        }

        lineStarting = match[0]!.endsWith('\n');

        final position2 = match.end;

        if (rule.newState != null) {
          if (rule.newState == '#pop') {
            stack.removeLast();
          } else if (rule.newState == '#group') {
            var notFound = true;

            for (final name in match.groupNames) {
              final group = match.namedGroup(name);

              if (group != null) {
                stack.add(name);
                notFound = false;
              }
            }

            if (notFound) {
              throw Exception(
                  '${rule.regExp} wanted to resolve the token dynamically but no group matched');
            }
          } else {
            stack.add(rule.newState!);
          }

          stateRules = rules[stack.last]!;
        } else if (position == position2) {
          throw '${rule.regExp} yielded empty string without stack change';
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
    final lines = split(newLineRe, source);

    if (!keepTrailingNewLine && lines.last.isEmpty) {
      lines.removeLast();
    }

    source = lines.join('\n');
    final scanner = StringScanner(source, sourceUrl: path);
    final tokens = <Token>[];

    for (final token in scan(scanner)) {
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
    final matches = pattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return <String>[text];
    }

    final result = <String>[];
    final length = matches.length;
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
