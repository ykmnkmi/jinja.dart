import '../../context.dart';
import '../../parser.dart';
import '../../undefined.dart';
import '../core.dart';

class ForStatement extends Statement {
  static ForStatement parse(Parser parser) {
    final elseReg = parser.getBlockEndReg('else');
    final endForReg = parser.getBlockEndReg('endfor');

    final targets = parser.parseAssignTarget();

    parser.scanner.expect(Parser.spacePlusReg);
    parser.scanner.expect('in');
    parser.scanner.expect(Parser.spacePlusReg);

    final iterable = parser.parseExpression(withCondition: false);
    Expression filter;

    if (parser.scanner.scan(Parser.ifReg)) {
      filter = parser.parseExpression(withCondition: false);
    }

    parser.scanner.expect(parser.blockEndReg);

    final body = parser.parseStatements([elseReg, endForReg]);
    Node orElse;

    if (parser.scanner.scan(elseReg)) {
      orElse = parser.parseStatements([endForReg]);
    }

    parser.scanner.expect(endForReg);

    return filter != null
        ? ForStatementWithFilter(targets, iterable, body, filter,
            orElse: orElse)
        : ForStatement(targets, iterable, body, orElse: orElse);
  }

  ForStatement(this.targets, this.iterable, this.body, {this.orElse})
      : _targetsLen = targets.length;

  final List<String> targets;
  final Expression iterable;
  final Node body;
  final Node orElse;

  final int _targetsLen;

  void unpack(Map<String, dynamic> data, dynamic current) {
    if (current is Iterable) {
      var list = current.toList(growable: false);

      if (list.length < _targetsLen) {
        throw Exception('not enough values to unpack '
            '(expected $_targetsLen, got ${list.length})');
      }

      if (list.length > _targetsLen) {
        throw Exception('too many values to unpack (expected $_targetsLen)');
      }

      if (list is List<MapEntry>) {
        list = list.map((e) => [e.key, e.value]).toList(growable: false);
      }

      for (var i = 0; i < _targetsLen; i++) {
        data[targets[i]] = list[i];
      }
    } else {}
  }

  Map<String, dynamic> getDataForContext(
      List values, int i, Undefined undefined) {
    dynamic prev = undefined, next = undefined;
    var current = values[i];

    if (i > 0) prev = values[i - 1];
    if (i < values.length - 1) next = values[i + 1];

    bool changed(dynamic item) {
      if (i == 0) return true;
      if (item == values[i - 1]) return false;
      return true;
    }

    final data = <String, dynamic>{
      'loop': LoopContext(i, values.length, prev, next, changed),
    };

    if (targets.length == 1) {
      if (current is MapEntry) {
        data[targets[0]] = [current.key, current.value];
      } else {
        data[targets[0]] = current;
      }
    } else {
      unpack(data, current);
    }

    return data;
  }

  void render(List list, Context context, StringBuffer buffer) {
    for (var i = 0; i < list.length; i++) {
      final data = getDataForContext(list, i, context.environment.undefined);
      context.apply(data, (context) {
        body.accept(buffer, context);
      });
    }
  }

  void loopIterable(Iterable values, Context context, StringBuffer buffer) {
    final list = values.toList(growable: false);
    render(list, context, buffer);
  }

  void loopMap(Map dict, Context context, StringBuffer buffer) {
    final list = dict.entries
        .map((entry) => [entry.key, entry.value])
        .toList(growable: false);
    render(list, context, buffer);
  }

  void loopString(String value, Context context, StringBuffer buffer) {
    final list = value.split('');
    render(list, context, buffer);
  }

  @override
  void accept(StringBuffer buffer, Context context) {
    final iterable = this.iterable.resolve(context);

    if (iterable == null) throw ArgumentError.notNull();

    if (iterable is Iterable && iterable.isNotEmpty) {
      loopIterable(iterable, context, buffer);
    } else if (iterable is Map && iterable.isNotEmpty) {
      loopMap(iterable, context, buffer);
    } else if (iterable is String && iterable.isNotEmpty) {
      loopString(iterable, context, buffer);
    } else {
      orElse?.accept(buffer, context);
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.writeln('for ${targets.join(', ')} in ${iterable.toDebugString()}');
    buffer.write('${body.toDebugString(level + 1)}');

    if (orElse != null) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('else');
      buffer.write('${orElse.toDebugString(level + 1)}');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('For($targets, $iterable, $body}');
    if (orElse != null) buffer.write(', orElse: $orElse');
    buffer.write(')');
    return buffer.toString();
  }
}

class ForStatementWithFilter extends ForStatement {
  ForStatementWithFilter(
    List<String> targets,
    Expression iterable,
    Node body,
    this.filter, {
    Node orElse,
  }) : super(targets, iterable, body, orElse: orElse);

  final Expression filter;

  List<dynamic> filterValues(Iterable values, Context context) {
    final list = values.toList(growable: false);
    final filteredList = [];

    for (var i = 0; i < list.length; i++) {
      final data = getDataForContext(list, i, context.environment.undefined);
      context.apply(data, (context) {
        if (toBool(filter.resolve(context))) filteredList.add(list[i]);
      });
    }

    return filteredList;
  }

  @override
  void loopIterable(Iterable values, Context context, StringBuffer buffer) {
    final list = filterValues(values, context);
    render(list, context, buffer);
  }

  @override
  void loopMap(Map dict, Context context, StringBuffer buffer) {
    final list = filterValues(
        dict.entries.map((entry) => [entry.key, entry.value]), context);
    render(list, context, buffer);
  }

  @override
  void loopString(String value, Context context, StringBuffer buffer) {
    final list = filterValues(value.split(''), context);
    render(list, context, buffer);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('for ${targets.join(', ')} in ${iterable.toDebugString()}');

    if (filter != null) {
      buffer.writeln(' if ${filter.toDebugString()}');
    } else {
      buffer.writeln();
    }

    buffer.write(body.toDebugString(level + 1));

    if (orElse != null) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('else');
      buffer.write('${orElse.toDebugString(level + 1)}');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final buffer =
        StringBuffer('ForWithFilter($targets, $iterable, $body, $filter}');
    if (orElse != null) buffer.write(', orElse: $orElse');
    buffer.write(')');
    return buffer.toString();
  }
}

class LoopContext {
  LoopContext(
      this.index0, this.length, this.previtem, this.nextitem, this.changed)
      : _cycle = CycleWrapper((args) => args[index0 % args.length]);

  final int index0;
  final int length;
  final dynamic previtem;
  final dynamic nextitem;
  final bool Function(dynamic) changed;

  dynamic _cycle;
  dynamic get cycle => _cycle;

  int get index => index0 + 1;
  bool get first => index0 == 0;
  bool get last => index == length;
  int get revindex => length - index0;
  int get revindex0 => length - index;
}

class CycleWrapper {
  CycleWrapper(this.function);

  final dynamic Function(List) function;

  dynamic call(List args) => function(args);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return function(invocation.positionalArguments);
    }

    return super.noSuchMethod(invocation);
  }
}
