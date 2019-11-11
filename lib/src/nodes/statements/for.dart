import '../../context.dart';
import '../../runtime.dart';
import '../core.dart';

class ForStatement extends Statement {
  ForStatement(this.targets, this.iterable, this.body, {this.orElse})
      : _targetsLen = targets.length;

  final List<String> targets;
  final Expression iterable;
  final Node body;
  final Node orElse;

  final int _targetsLen;

  void unpack(Map<String, Object> data, Object current) {
    if (current is Iterable) {
      List<Object> list = current.toList();

      if (list.length < _targetsLen) {
        throw ArgumentError('not enough values to unpack '
            '(expected $_targetsLen, got ${list.length})');
      }

      if (list.length > _targetsLen) {
        throw ArgumentError(
            'too many values to unpack (expected $_targetsLen)');
      }

      for (int i = 0; i < _targetsLen; i++) {
        data[targets[i]] = list[i];
      }
    }
  }

  Map<String, Object> getDataForContext(
      List<Object> values, int i, Undefined undefined) {
    Object prev = undefined;
    Object next = undefined;
    Object current = values[i];

    if (i > 0) prev = values[i - 1];
    if (i < values.length - 1) next = values[i + 1];

    bool changed(Object item) {
      if (i == 0) return true;
      if (item == values[i - 1]) return false;
      return true;
    }

    Map<String, Object> data = <String, Object>{
      'loop': LoopContext(i, values.length, prev, next, changed),
    };

    if (targets.length == 1) {
      data[targets[0]] = current;
    } else {
      unpack(data, current);
    }

    return data;
  }

  void render(List<Object> list, Context context, StringBuffer buffer) {
    for (int i = 0; i < list.length; i++) {
      Map<String, Object> data =
          getDataForContext(list, i, context.env.undefined);
      context.apply(data, (Context context) {
        body.accept(buffer, context);
      });
    }
  }

  void loopIterable(
      Iterable<Object> values, Context context, StringBuffer buffer) {
    List<Object> list = values.toList();
    render(list, context, buffer);
  }

  void loopMap(Map<Object, Object> dict, Context context, StringBuffer buffer) {
    List<List<Object>> list = dict.entries
        .map((MapEntry<Object, Object> entry) =>
            <Object>[entry.key, entry.value])
        .toList();
    render(list, context, buffer);
  }

  void loopString(String value, Context context, StringBuffer buffer) {
    List<String> list = value.split('');
    render(list, context, buffer);
  }

  @override
  void accept(StringBuffer buffer, Context context) {
    Object iterable = this.iterable.resolve(context);
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
    StringBuffer buffer = StringBuffer(' ' * level);
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
    StringBuffer buffer = StringBuffer('For($targets, $iterable, $body}');
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

  Map<String, Object> getDataForFilter(List<Object> values, int i) {
    Object current = values[i];

    Map<String, Object> data = <String, Object>{};

    if (targets.length == 1) {
      if (current is MapEntry) {
        data[targets.first] = <Object>[current.key, current.value];
      } else {
        data[targets.first] = current;
      }
    } else {
      unpack(data, current);
    }

    return data;
  }

  List<Object> filterValues(Iterable<Object> values, Context context) {
    List<Object> list = values.toList();
    List<Object> filteredList = <Object>[];

    for (int i = 0; i < list.length; i++) {
      Map<String, Object> data = getDataForFilter(list, i);

      context.apply(data, (Context context) {
        if (toBool(filter.resolve(context))) filteredList.add(list[i]);
      });
    }

    return filteredList;
  }

  @override
  void loopIterable(
      Iterable<Object> values, Context context, StringBuffer buffer) {
    List<Object> list = filterValues(values, context);
    render(list, context, buffer);
  }

  @override
  void loopMap(Map<Object, Object> dict, Context context, StringBuffer buffer) {
    List<Object> list = filterValues(
        dict.entries.map((MapEntry<Object, Object> entry) =>
            <Object>[entry.key, entry.value]),
        context);
    render(list, context, buffer);
  }

  @override
  void loopString(String value, Context context, StringBuffer buffer) {
    List<Object> list = filterValues(value.split(''), context);
    render(list, context, buffer);
  }

  @override
  String toDebugString([int level = 0]) {
    StringBuffer buffer = StringBuffer(' ' * level);
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
    StringBuffer buffer =
        StringBuffer('ForWithFilter($targets, $iterable, $body, $filter}');
    if (orElse != null) buffer.write(', orElse: $orElse');
    buffer.write(')');
    return buffer.toString();
  }
}
