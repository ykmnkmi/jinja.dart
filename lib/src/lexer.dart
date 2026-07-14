import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:string_scanner/string_scanner.dart';

part 'lexer/identifier.dart';
part 'lexer/token_reader.dart';
part 'lexer/token_type.dart';
part 'lexer/token.dart';

/// Cache for the [Lexer]s.
///
/// Exists in order to be able to have multiple environments with the same
/// lexer.
final Expando<Lexer> _lexerCache = Expando<Lexer>();

final RegExp _allWhiteSpaceRe = RegExp(r'^\s+$');
final RegExp _whiteSpaceRe = RegExp(r'\s+');
final RegExp _newLineRe = RegExp('(\r\n|\r|\n)');

final RegExp _stringRe = RegExp(
  "('([^'\\\\]*(?:\\\\.[^'\\\\]*)*)'"
  '|"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)")',
  dotAll: true,
);

final RegExp _integerRe = RegExp(
  '(0x(_?[\\da-f])+' // hex
  '|[1-9](_?\\d)*' // decimal
  '|0(_?0)*)', // decimal zero
  caseSensitive: false,
);

final RegExp _floatRe = RegExp(
  '(?<!\\.)' // does not start with a `.`
  '(\\d+_)*\\d+' // digits, possibly `_` separated
  '((\\.(\\d+_)*\\d+)?' // optional fractional part
  'e[+-]?(\\d+_)*\\d+' // exponent part
  '|\\.(\\d+_)*\\d+)', // required fractional part
  caseSensitive: false,
);

/// Class that throws a [TemplateSyntaxError] if called.
///
/// Used by [Lexer] to specify known errors.
final class _Failure {
  _Failure(this.message);

  final String message;

  Never call({String? path, int? line}) {
    throw TemplateSyntaxError(message, path: path, line: line);
  }
}

enum _RuleState { pop, byGroup }

sealed class _Rule {
  _Rule(this.regExp, [this.newState]);

  final RegExp regExp;

  final _RuleState? newState;
}

final class _SingleTokenRule extends _Rule {
  _SingleTokenRule(super.regExp, this.token, [super.newState]);

  final String token;
}

final class _MultiTokenRule extends _Rule {
  _MultiTokenRule(super.regExp, this.tokens, [super.newState])
    : optionalLStrip = false;

  _MultiTokenRule.optionalLStrip(super.regExp, this.tokens, [super.newState])
    : optionalLStrip = true;

  final List<Object> tokens;

  /// A bool for marking a point in the state that can have lstrip applied.
  final bool optionalLStrip;
}

/// Class that implements a lexer for a given environment.
///
/// Automatically created by [Environment] class, usually you do not have to do that.
/// Not that the lexer is not automatically bound to an environment. Multiple
/// environments can share the same lexer.
final class Lexer {
  /// Return a lexer which is probably cached.
  factory Lexer(Environment environment) {
    return _lexerCache[environment] ??= Lexer._(environment);
  }

  Lexer._(Environment environment)
    : _rules = <String, List<_Rule>>{},
      leftStripBlocks = environment.leftStripBlocks,
      keepTrailingNewLine = environment.keepTrailingNewLine,
      newLine = environment.newLine {
    String escape(String pattern) {
      return RegExp.escape(pattern);
    }

    RegExp compile(String pattern) {
      return RegExp(pattern, dotAll: true, multiLine: true);
    }

    // Lexing rules for tags.
    var tagRules = <_Rule>[
      _SingleTokenRule(_whiteSpaceRe, TokenType.whitespace),
      _SingleTokenRule(_floatRe, TokenType.float),
      _SingleTokenRule(_integerRe, TokenType.integer),
      _SingleTokenRule(nameRe, TokenType.name),
      _SingleTokenRule(_stringRe, TokenType.string),
      _SingleTokenRule(_operatorRe, TokenType.operator),
    ];

    // Block suffix if trimming is enabled.
    var blockSuffixRe = environment.trimBlocks ? '\\n?' : '';

    var commentStartRe = escape(environment.commentStart);
    var commentEndRe = escape(environment.commentEnd);

    var variableStartRe = escape(environment.variableStart);
    var variableEndRe = escape(environment.variableEnd);

    var blockStartRe = escape(environment.blockStart);
    var blockEndRe = escape(environment.blockEnd);

    // Compile all the rules from the environment into a list of rules.
    var rootTagRules = <(String, String, Pattern?)>[
      (TokenType.commentBegin, environment.commentStart, commentStartRe),
      (TokenType.variableBegin, environment.variableStart, variableStartRe),
      (TokenType.blockBegin, environment.blockStart, blockStartRe),
    ];

    if (environment.lineCommentPrefix case var prefix?) {
      rootTagRules.add((
        TokenType.lineCommentBegin,
        prefix,
        '(?:^|(?<=\\S))[^\\S\r\n]*$prefix',
      ));
    }

    if (environment.lineStatementPrefix case var prefix?) {
      rootTagRules.add((
        TokenType.lineStatementBegin,
        prefix,
        '^[ \t\v]*$prefix',
      ));
    }

    // Assemble the root lexing rules. Because '|' is ungreedy
    rootTagRules.sort((a, b) => b.$2.length.compareTo(a.$2.length));

    var rootRawRe =
        '(?<raw_begin>$blockStartRe(-|\\+|)\\s*raw\\s*'
        '(?:-$blockEndRe\\s*|$blockEndRe))';

    var rootPartsRe = <String>[
      rootRawRe,
      for (var (type, _, pattern) in rootTagRules) '(?<$type>$pattern(-|\\+|))',
    ].join('|');

    // Global lexing rules.
    _rules['root'] = <_Rule>[
      // Directives.
      _MultiTokenRule.optionalLStrip(compile('(.*?)(?:$rootPartsRe)'), <Object>[
        TokenType.data,
        _RuleState.byGroup,
      ], _RuleState.byGroup),
      // Data.
      _SingleTokenRule(compile('.+'), TokenType.data),
    ];

    // Comments.
    _rules[TokenType.commentBegin] = <_Rule>[
      _MultiTokenRule(
        compile(
          '(.*?)((?:\\+$commentEndRe|-$commentEndRe\\s*'
          '|$commentEndRe$blockSuffixRe))',
        ),
        <String>[TokenType.comment, TokenType.commentEnd],
        _RuleState.pop,
      ),
      _MultiTokenRule(compile('(.)'), <Object>[
        _Failure('Missing end of comment tag.'),
      ]),
    ];

    // Blocks.
    _rules[TokenType.blockBegin] = <_Rule>[
      _SingleTokenRule(
        compile(
          '(?:\\+$blockEndRe|-$blockEndRe\\s*'
          '|$blockEndRe$blockSuffixRe)',
        ),
        TokenType.blockEnd,
        _RuleState.pop,
      ),
      ...tagRules,
    ];

    // Variables.
    _rules[TokenType.variableBegin] = <_Rule>[
      _SingleTokenRule(
        compile('-$variableEndRe\\s*|$variableEndRe'),
        TokenType.variableEnd,
        _RuleState.pop,
      ),
      ...tagRules,
    ];

    // Raw block.
    _rules[TokenType.rawBegin] = <_Rule>[
      _MultiTokenRule.optionalLStrip(
        compile(
          '(.*?)((?:$blockStartRe(-|\\+|))\\s*endraw\\s*'
          '(?:\\+$blockEndRe|-$blockEndRe\\s*'
          '|$blockEndRe$blockSuffixRe))',
        ),
        <Object>[TokenType.data, TokenType.rawEnd],
        _RuleState.pop,
      ),
      _MultiTokenRule(compile('(.)'), <Object>[
        _Failure('Missing end of raw directive.'),
      ]),
    ];

    // Line comments.
    if (environment.lineCommentPrefix != null) {
      _rules[TokenType.lineCommentBegin] = <_Rule>[
        _MultiTokenRule(compile('(.*?)()(?=\n|\$)'), <Object>[
          TokenType.lineComment,
          TokenType.lineCommentEnd,
        ], _RuleState.pop),
      ];
    }

    // Line statements.
    if (environment.lineStatementPrefix != null) {
      _rules[TokenType.lineStatementBegin] = <_Rule>[
        _SingleTokenRule(
          compile('\\s*(\n|\$)'),
          TokenType.lineStatementEnd,
          _RuleState.pop,
        ),
        ...tagRules,
      ];
    }
  }

  final Map<String, List<_Rule>> _rules;

  final bool leftStripBlocks;

  final bool keepTrailingNewLine;

  final String newLine;

  String _normalizeNewLines(String value) {
    return value.replaceAll(_newLineRe, newLine);
  }

  /// This method tokenizes the text and returns the tokens in a sync generator.
  ///
  /// Use this method if you just want to tokkenize a template.
  Iterable<Token> scan(String source, {String? path, String? state}) sync* {
    const endTokens = <String>[
      TokenType.variableEnd,
      TokenType.blockEnd,
      TokenType.lineStatementEnd,
    ];

    var lines = split(_newLineRe, source);

    if (!keepTrailingNewLine && lines.last.isEmpty) {
      lines.removeLast();
    }

    source = lines.join('\n');

    var scanner = StringScanner(source, sourceUrl: path);

    var stack = <String>['root'];
    var balancingStack = <String>[];

    if (state != null && state != 'root') {
      assert(state == 'variable' || state == 'block');
      stack.add('${state}_start');
    }

    var stateRules = _rules[stack.last]!;
    var position = 0;
    var line = 1;
    var newLinesStripped = 0;
    var lineStarting = true;

    while (true) {
      var breakLoop = false;

      // Tokenizer loop.
      for (var rule in stateRules) {
        // If no match we try again with the next rule.
        if (!scanner.scan(rule.regExp)) {
          continue;
        }

        var match = scanner.lastMatch as RegExpMatch;

        if (rule is _MultiTokenRule) {
          var groups = List<String?>.generate(
            match.groupCount,
            (i) => match.group(i + 1),
          );

          if (rule.optionalLStrip) {
            // Rule supports lStrip. Match will look like text, block type,
            // whitespace control, type, control, ...
            var text = groups[0]!;

            // Skipping the text and first type, every other group is the
            // whitespace control for each type. One of the groups will be
            // -, +, or empty string instead of null.
            String? stripSign;

            for (var i = 2; i < groups.length; i += 2) {
              if (groups[i] != null) {
                stripSign = groups[i];
                break;
              }
            }

            if (stripSign == '-') {
              // Strip all whitespace between the text and the tag.
              var stripped = text.trimRight();
              newLinesStripped = count(text, '\n', stripped.length);
              groups[0] = stripped;
            } else if (stripSign != '+' && leftStripBlocks) {
              var isVariable =
                  match.groupNames.contains(TokenType.variableBegin) &&
                  match.namedGroup(TokenType.variableBegin) != null;

              if (!isVariable) {
                // The start of text between the last newline and the tag.
                var lastPosition = text.lastIndexOf('\n') + 1;

                if (lastPosition > 0 || lineStarting) {
                  if (_allWhiteSpaceRe.hasMatch(text.substring(lastPosition))) {
                    groups[0] = text.substring(0, lastPosition);
                  }
                }
              }
            }
          }

          for (var i = 0; i < rule.tokens.length; i += 1) {
            var token = rule.tokens[i];

            // Failure group.
            if (token is _Failure) {
              token(line: line);
            }

            // #bygroup is a bit more complex, in that case we yield for the
            // current token the first named group that matched.
            if (token == _RuleState.byGroup) {
              String? group;

              for (var name in match.groupNames) {
                group = match.namedGroup(name);

                if (group != null) {
                  yield Token(line, name, group);
                  line += count(group, '\n');
                  break;
                }
              }

              if (group == null) {
                throw StateError(
                  "'${rule.regExp}' wanted to resolve the token dynamically "
                  'but no group matched.',
                );
              }
            }
            // Normal group.
            else if (token is String) {
              if (groups[i] case var data?) {
                if (data.isNotEmpty || !_ignoreIfEmpty.contains(token)) {
                  yield Token(line, token, data);
                }

                line += count(data, '\n') + newLinesStripped;
                newLinesStripped = 0;
              }
            } else {
              assert(false, 'Unreachable.');
            }
          }
        } else if (rule is _SingleTokenRule) {
          // Strings as token just are yielded as it.

          // We only match blocks and variables if braces / parentheses are
          // balanced. Continue parsing with the lower rule which is the
          // operator rule. Do this only if the end tags look like operators.
          if (balancingStack.isNotEmpty && endTokens.contains(rule.token)) {
            scanner.position = match.start;
            continue;
          }

          var data = match[0]!;
          var token = rule.token;

          // Update brace/parentheses balance.
          if (token == TokenType.operator) {
            if (data == '(') {
              balancingStack.add(')');
            } else if (data == '[') {
              balancingStack.add(']');
            } else if (data == '{') {
              balancingStack.add('}');
            } else if (data == ')' || data == ']' || data == '}') {
              if (balancingStack.isEmpty) {
                throw TemplateSyntaxError("Unexpected '$data'.", line: line);
              }

              var expected = balancingStack.removeLast();

              if (data != expected) {
                throw TemplateSyntaxError(
                  "Unexpected '$data', expected '$expected'.",
                  line: line,
                );
              }
            }
          }

          if (data.isNotEmpty || !_ignoreIfEmpty.contains(token)) {
            // Yield items.
            yield Token(line, token, data);
          }

          line += count(data, '\n');
        }

        lineStarting = match[0]!.endsWith('\n');

        // Fetch new position into new variable so that we can check
        // if there is a internal parsing error which would result in an
        // infinite loop.
        var position2 = match.end;

        // Handle state changes.
        if (rule.newState case var newState?) {
          if (newState == _RuleState.pop) {
            // Remove the uppermost state.
            stack.removeLast();
          } else if (newState == _RuleState.byGroup) {
            // Resolve the new state by group checking.
            String? newState;

            for (var name in match.groupNames) {
              if (match.namedGroup(name) != null) {
                newState = name;
                break;
              }
            }

            if (newState == null) {
              throw StateError(
                "'${rule.regExp}' wanted to resolve the new state dynamically "
                'but no group matched.',
              );
            }

            stack.add(newState);
          } else {
            assert(false, 'Direct state name given.');
          }

          stateRules = _rules[stack.last]!;
        } else if (position2 == position) {
          // We are still at the same position and no stack change.
          // This means a loop without break condition, avoid that and throw
          // error.
          throw StateError(
            "'${rule.regExp}' yielded empty string without stack change.",
          );
        }

        // Publish new function and start again.
        position = position2;
        breakLoop = true;
        break;
      }

      // If loop terminated without break we have not found a single match
      // either we are at the end of the file or we have a problme.
      if (!breakLoop) {
        // End of the text.
        if (scanner.isDone) {
          yield Token.simple(line, TokenType.eof);
          return;
        }

        // Something went wrong.
        throw TemplateSyntaxError(
          "Unexpected char '${scanner.rest[0]}' at $position.",
          line: line,
        );
      }
    }
  }

  Iterable<Token> normalize(Iterable<Token> tokens) sync* {
    for (var token in tokens) {
      if (_ignoredTokens.contains(token.type)) {
        continue;
      }

      if (token.type == TokenType.lineStatementBegin) {
        yield token.change(type: TokenType.blockBegin);
      } else if (token.type == TokenType.lineStatementEnd) {
        yield token.change(type: TokenType.blockEnd);
      } else if (token.type case TokenType.rawBegin || TokenType.rawEnd) {
        // We are not interested in those tokens in the parser.
        continue;
      } else if (token.type == TokenType.data) {
        yield token.change(value: _normalizeNewLines(token.value));
      } else if (token.type == TokenType.string) {
        var value = token.value;
        var content = _normalizeNewLines(value.substring(1, value.length - 1));
        yield token.change(value: content);
      } else if (token.type case TokenType.integer || TokenType.float) {
        yield token.change(value: token.value.replaceAll('_', ''));
      } else if (token.type == TokenType.operator) {
        yield Token.simple(token.line, _operators[token.value]!);
      } else {
        yield token;
      }
    }
  }

  Iterable<Token> tokenize(String source, {String? path}) {
    var tokens = scan(source, path: path);
    return normalize(tokens);
  }

  static int count(String string, String char, [int offset = 0]) {
    var count = 0;

    for (var i = offset; i < string.length; i += 1) {
      if (string[i] == char) {
        count += 1;
      }
    }

    return count;
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
