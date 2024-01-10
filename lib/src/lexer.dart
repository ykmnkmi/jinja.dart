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

enum RuleState {
  pop,
  group,
}

sealed class Rule {
  Rule(this.regExp, [this.newState]);

  final RegExp regExp;

  final RuleState? newState;
}

final class SingleTokenRule extends Rule {
  SingleTokenRule(super.regExp, this.token, [super.newState]);

  final String token;
}

final class MultiTokenRule extends Rule {
  MultiTokenRule(super.regExp, this.tokens, [super.newState])
      : optionalLStrip = false;

  MultiTokenRule.optionalLStrip(super.regExp, this.tokens, [super.newState])
      : optionalLStrip = true;

  final List<String> tokens;

  final bool optionalLStrip;
}

final class Lexer {
  static final RegExp newLineRe = RegExp('(\r\n|\r|\n)');
  static final RegExp leftStripUnlessRe = RegExp('[^ \\t]');
  static final RegExp whitespaceRe = RegExp(r'\s+');
  static final RegExp nameRe = RegExp('[a-zA-Z\$_][a-zA-Z0-9\$_]*');
  static final RegExp stringRe = RegExp(
      '(\'([^\'\\\\]*(?:\\\\.[^\'\\\\]*)*)\'|"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)")');
  static final RegExp integerRe = RegExp('(0[xX](_?[\\da-fA-F])+|\\d(_?\\d)*)');
  static final RegExp floatRe = RegExp(
      '(?<!\\.)(\\d+_)*\\d+((\\.(\\d+_)*\\d+)?[eE][+\\-]?(\\d+_)*\\d+|\\.(\\d+_)*\\d+)');
  static final RegExp operatorRe = RegExp(
      '\\+|-|\\/\\/|\\/|\\*\\*|\\*|%|~|\\[|\\]|\\(|\\)|{|}|==|!=|<=|>=|=|<|>|\\.|:|\\||,|;');

  /// Cached [Lexer]'s
  static final Expando<Lexer> lexers = Expando<Lexer>();

  factory Lexer.cached(Environment environment) {
    return lexers[environment] ??= Lexer(environment);
  }

  factory Lexer(Environment environment) {
    var blockSuffixRe = environment.trimBlocks ? '\\n?' : '';

    var commentStartRe = RegExp.escape(environment.commentStart);
    var commentEndRe = RegExp.escape(environment.commentEnd);
    var commentEnd = RegExp(
        '(.*?)((?:\\+$commentEndRe|-$commentEndRe\\s*|$commentEndRe$blockSuffixRe))',
        dotAll: true);

    var variableStartRe = RegExp.escape(environment.variableStart);
    var variableEndRe = RegExp.escape(environment.variableEnd);
    var variableEnd = RegExp('-$variableEndRe\\s*|$variableEndRe');

    var blockStartRe = RegExp.escape(environment.blockStart);
    var blockEndRe = RegExp.escape(environment.blockEnd);
    var blockEnd =
        RegExp('(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe)');

    var tagRules = <Rule>[
      SingleTokenRule(whitespaceRe, 'whitespace'),
      SingleTokenRule(floatRe, 'float'),
      SingleTokenRule(integerRe, 'integer'),
      SingleTokenRule(nameRe, 'name'),
      SingleTokenRule(stringRe, 'string'),
      SingleTokenRule(operatorRe, 'operator'),
    ];

    var rootTagRules = <(String, String, Pattern?)>[
      ('comment_start', environment.commentStart, commentStartRe),
      ('variable_start', environment.variableStart, variableStartRe),
      ('block_start', environment.blockStart, blockStartRe),
      if (environment.lineCommentPrefix case var prefix?)
        ('linecomment_start', prefix, '(?:^|(?<=\\S))[^\\S\r\n]*$prefix'),
      if (environment.lineStatementPrefix case var prefix?)
        ('linestatement_start', prefix, '^[ \t\v]*$prefix'),
    ];

    rootTagRules.sort((a, b) => b.$2.length.compareTo(a.$2.length));

    var rawStart = RegExp(
        '(?<raw_start>$blockStartRe(-|\\+|)\\s*raw\\s*(?:-$blockEndRe\\s*|$blockEndRe))');
    var rawEnd = RegExp(
        '(.*?)((?:$blockStartRe(-|\\+|))\\s*endraw\\s*'
        '(?:\\+$blockEndRe|-$blockEndRe\\s*|$blockEndRe$blockSuffixRe))',
        dotAll: true);

    var rootParts = <String>[
      rawStart.pattern,
      for (var rule in rootTagRules) '(?<${rule.$1}>${rule.$3}(-|\\+|))',
    ];

    var rootPartsRe = rootParts.join('|');
    var data = RegExp('(.*?)(?:$rootPartsRe)', dotAll: true, multiLine: true);

    var rules = <String, List<Rule>>{
      'root': <Rule>[
        MultiTokenRule.optionalLStrip(
          data,
          <String>['data', '#group'],
          RuleState.group,
        ),
        SingleTokenRule(
          RegExp('.+', dotAll: true),
          'data',
        ),
      ],
      'comment_start': <Rule>[
        MultiTokenRule(
          commentEnd,
          <String>['comment', 'comment_end'],
          RuleState.pop,
        ),
        MultiTokenRule(
          RegExp('(.)', dotAll: true),
          <String>['@missing end of comment tag'],
        ),
      ],
      'variable_start': <Rule>[
        SingleTokenRule(
          variableEnd,
          'variable_end',
          RuleState.pop,
        ),
        ...tagRules,
      ],
      'block_start': <Rule>[
        SingleTokenRule(
          blockEnd,
          'block_end',
          RuleState.pop,
        ),
        ...tagRules,
      ],
      'raw_start': <Rule>[
        MultiTokenRule.optionalLStrip(
          rawEnd,
          <String>['data', 'raw_end'],
          RuleState.pop,
        ),
        MultiTokenRule(
          RegExp('(.)', dotAll: true),
          <String>['@missing end of raw directive'],
        ),
      ],
      if (environment.lineCommentPrefix != null)
        'linecomment_start': <Rule>[
          MultiTokenRule(
            RegExp('(.*?)()(?=\n|\$)', dotAll: true),
            <String>['linecomment', 'linecomment_end'],
            RuleState.pop,
          ),
        ],
      if (environment.lineStatementPrefix != null)
        'linestatement_start': <Rule>[
          SingleTokenRule(
            RegExp('\\s*(\n|\$)'),
            'linestatement_end',
            RuleState.pop,
          ),
          ...tagRules,
        ],
    };

    return Lexer.from(
      rules: rules,
      leftStripBlocks: environment.leftStripBlocks,
      newLine: environment.newLine,
      keepTrailingNewLine: environment.keepTrailingNewLine,
    );
  }

  const Lexer.from({
    required this.rules,
    required this.newLine,
    this.leftStripBlocks = false,
    this.keepTrailingNewLine = false,
  });

  final Map<String, List<Rule>> rules;

  final bool leftStripBlocks;

  final bool keepTrailingNewLine;

  final String newLine;

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

        if (rule case MultiTokenRule rule) {
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
                leftStripBlocks &&
                (!match.groupNames.contains('variable_start') ||
                    match.namedGroup('variable_start') == null)) {
              var lastPosition = text.lastIndexOf('\n') + 1;

              if (lastPosition > 0 || lineStarting) {
                var index =
                    text.substring(lastPosition).indexOf(leftStripUnlessRe);

                if (index == -1) {
                  groups[0] = groups[0]!.substring(0, lastPosition);
                }
              }
            }
          }

          for (var i = 0; i < rule.tokens.length; i += 1) {
            var token = rule.tokens[i];

            if (token.startsWith('@')) {
              // TODO(lexer): update error
              throw Exception();
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
                // TODO(lexer): update error
                throw Exception('${rule.regExp} wanted to resolve the token '
                    'dynamically but no group matched');
              }
            } else {
              if (groups[i] case var data?) {
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
              } else {
                tokens.add(Token.simple(line, token));
              }
            }
          }
        } else if (rule case SingleTokenRule rule) {
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
                throw TemplateSyntaxError("Unexpected '$data'");
              }

              var expected = balancingStack.removeLast();

              if (data != expected) {
                throw TemplateSyntaxError(
                    "Unexpected '$data', expected '$expected'");
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
          // TODO(lexer): update error
          throw Exception();
        }

        lineStarting = match[0]!.endsWith('\n');

        if (rule.newState == RuleState.pop) {
          stack.removeLast();
        } else if (rule.newState == RuleState.group) {
          var names = <String>[
            for (var name in match.groupNames)
              if (match.namedGroup(name) != null) name
          ];

          if (names.isEmpty) {
            // TODO(lexer): add error message
            throw TemplateSyntaxError('');
          }

          stack.addAll(names);
        } else if (position == match.end) {
          // TODO(lexer): add error message
          throw TemplateSyntaxError('');
        }

        stateRules = rules[stack.last]!;
        position = match.end;
        notBreak = false;
        break;
      }

      if (notBreak) {
        if (scanner.isDone) {
          return tokens;
        }

        var char = scanner.rest[0];
        var position = scanner.position;
        throw TemplateSyntaxError('Unexpected char $char at $position');
      }
    }
  }

  Iterable<Token> tokenize(String source, {String? path}) sync* {
    var lines = split(newLineRe, source);

    if (!keepTrailingNewLine && lines.last.isEmpty) {
      lines.removeLast();
    }

    source = lines.join('\n');

    var scanner = StringScanner(source, sourceUrl: path);

    for (var token in scan(scanner)) {
      if (ignoredTokens.any(token.test)) {
        continue;
      } else if (token.test('linestatement_start')) {
        yield token.change(type: 'block_start');
      } else if (token.test('linestatement_end')) {
        yield token.change(type: 'block_end');
      } else if (token.test('data')) {
        yield token.change(value: normalizeNewLines(token.value));
      } else if (token.test('string')) {
        var value = token.value;
        value = normalizeNewLines(value.substring(1, value.length - 1));
        yield token.change(value: value);
      } else if (token.test('integer') || token.test('float')) {
        yield token.change(value: token.value.replaceAll('_', ''));
      } else if (token.test('operator')) {
        yield Token.simple(token.line, operators[token.value]!);
      } else {
        yield token;
      }
    }

    yield Token.simple(source.length, 'eof');
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
