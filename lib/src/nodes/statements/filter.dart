import '../../context.dart';
import '../core.dart';
import '../expressions/filter.dart';

class FilterBlockStatement extends Statement {
  FilterBlockStatement(this.filters, this.body);

  final List<Filter> filters;
  final Node body;

  @override
  void accept(StringBuffer buffer, Context context) {
    var result;

    if (body is Expression) {
      result = (body as Expression).resolve(context);
    } else {
      final temp = StringBuffer();
      body.accept(temp, context);
      result = temp.toString();
    }

    for (var filter in filters) {
      result = filter.filter(context, result);
    }

    buffer.write(result);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('filter ${filters.first.toDebugString()}');

    for (var filter in filters.sublist(1)) {
      buffer.write(' | ${filter.toDebugString()}');
    }

    buffer.write('\n${body.toDebugString(level + 1)}');
    return buffer.toString();
  }

  @override
  String toString() => 'FilterBlock($filters, $body)';
}
