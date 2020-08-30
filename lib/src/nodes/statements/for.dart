import '../../context.dart';
import '../../runtime.dart';
import '../core.dart';

/// Class representing a node which makes up a for statement
class ForStatement extends Statement {
  ForStatement(this.targets, this.iterable, this.body, {this.orElse})
      : _targetsLength = targets.length;

  final List<String> targets;

  final Expression iterable;

  final Node body;

  final Node? orElse;

  final int _targetsLength;

  void unpack(Map<String, dynamic> data, dynamic current) {
    if (current is Iterable) {
      final list = current.toList();

      if (list.length < _targetsLength) {
        throw ArgumentError(
            'not enough values to unpack (expected $_targetsLength, got ${list.length})');
      }

      if (list.length > _targetsLength) {
        throw ArgumentError(
            'too many values to unpack (expected $_targetsLength)');
      }

      for (var i = 0; i < _targetsLength; i++) {
        data[targets[i]] = list[i];
      }
    }
  }

  Map<String, dynamic> getDataForContext(
      List values, int i, Undefined undefined) {
    final current = values[i];
    var prev = undefined as dynamic;
    var next = undefined as dynamic;

    if (i > 0) {
      prev = values[i - 1];
    }

    if (i < values.length - 1) {
      next = values[i + 1];
    }

    final changed = (item) {
      if (i == 0) {
        return true;
      }

      if ((item is List ? item[0] : item) == values[i - 1]) {
        return false;
      }

      return true;
    };

    final data = <String, dynamic>{
      'loop': LoopContext(i, values.length, prev, next, changed)
    };

    if (targets.length == 1) {
      data[targets[0]] = current;
    } else {
      unpack(data, current);
    }

    return data;
  }

  void render(List list, Context context, StringSink outSink) {
    for (var i = 0; i < list.length; i++) {
      final data = getDataForContext(list, i, context.environment.undefined);
      context.apply(data, (context) {
        body.accept(outSink, context);
      });
    }
  }

  void loopIterable(Iterable values, Context context, StringSink outSink) {
    render(values.toList(), context, outSink);
  }

  void loopMap(Map dict, Context context, StringSink outSink) {
    final list = dict.entries.map((entry) => [entry.key, entry.value]).toList();
    render(list, context, outSink);
  }

  void loopString(String value, Context context, StringSink outSink) {
    render(value.split(''), context, outSink);
  }

  @override
  void accept(StringSink outSink, Context context) {
    final iterable = this.iterable.resolve(context);

    if (iterable == null) {
      // TODO: compare error message
      throw ArgumentError.notNull('iterable');
    }

    if (iterable is Iterable && iterable.isNotEmpty) {
      loopIterable(iterable, context, outSink);
    } else if (iterable is Map && iterable.isNotEmpty) {
      loopMap(iterable, context, outSink);
    } else if (iterable is String && iterable.isNotEmpty) {
      loopString(iterable, context, outSink);
    } else {
      orElse?.accept(outSink, context);
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer
      ..write('for ')
      ..write(targets.join(', '))
      ..write(' in ')
      ..writeln(iterable.toDebugString())
      ..write(body.toDebugString(level + 1));

    if (orElse != null) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('else');
      buffer.write(orElse!.toDebugString(level + 1));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('For(');
    buffer
      ..write(targets)
      ..write(', ')
      ..write(iterable)
      ..write(', ')
      ..write(body)
      ..write(')');

    if (orElse != null) {
      buffer..write(', orElse: ')..write(orElse);
    }

    buffer.write(')');
    return buffer.toString();
  }
}

class ForStatementWithFilter extends ForStatement {
  ForStatementWithFilter(
      List<String> targets, Expression iterable, Node body, this.filter,
      {Node? orElse})
      : super(targets, iterable, body, orElse: orElse);

  final Expression? filter;

  Map<String, dynamic> getDataForFilter(List values, int i) {
    final current = values[i];
    final data = <String, dynamic>{};

    if (targets.length == 1) {
      if (current is MapEntry) {
        data[targets.first] = [current.key, current.value];
      } else {
        data[targets.first] = current;
      }
    } else {
      unpack(data, current);
    }

    return data;
  }

  List filterValues(Iterable values, Context context) {
    final list = values.toList();
    final filteredList = [];

    for (var i = 0; i < list.length; i++) {
      final data = getDataForFilter(list, i);

      context.apply(data, (context) {
        if (filter != null && toBool(filter!.resolve(context))) {
          filteredList.add(list[i]);
        }
      });
    }

    return filteredList;
  }

  @override
  void loopIterable(Iterable values, Context context, StringSink outSink) {
    render(filterValues(values, context), context, outSink);
  }

  @override
  void loopMap(Map dict, Context context, StringSink outSink) {
    final pairs = dict.entries.map((entry) => [entry.key, entry.value]);
    render(filterValues(pairs, context), context, outSink);
  }

  @override
  void loopString(String value, Context context, StringSink outSink) {
    render(filterValues(value.split(''), context), context, outSink);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer
      ..write('for ')
      ..write(targets.join(', '))
      ..write(' in ')
      ..write(iterable.toDebugString());

    if (filter != null) {
      buffer
        ..write(' if ')
        ..writeln(filter!.toDebugString());
    } else {
      buffer.writeln();
    }

    buffer.write(body.toDebugString(level + 1));

    if (orElse != null) {
      buffer.writeln();
      buffer.write(' ' * level);
      buffer.writeln('else');
      buffer.write(orElse!.toDebugString(level + 1));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer('ForWithFilter(');
    buffer
      ..write(targets)
      ..write(', ')
      ..write(iterable)
      ..write(', ')
      ..write(body)
      ..write(', ')
      ..write(filter)
      ..write(')');

    if (orElse != null) {
      buffer..write(', orElse: ')..write(orElse);
    }

    buffer.write(')');
    return buffer.toString();
  }
}
