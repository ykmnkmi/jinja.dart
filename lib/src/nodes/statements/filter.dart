import '../../context.dart';
import '../core.dart';
import '../expressions/filter.dart';

class FilterBlockStatement extends Statement {
  FilterBlockStatement(this.filter, this.body);

  final Filter filter;
  final Node body;

  @override
  void accept(StringBuffer buffer, Context context) {
    final temp = StringBuffer();
    body.accept(temp, context);
    buffer.write(filter.filter(context, temp.toString()));
  }

  @override
  String toDebugString([int level = 0]) =>
      ' ' * level +
      'filter ${filter.toDebugString()}\n${body.toDebugString(level + 1)}';

  @override
  String toString() => 'FilterBlock($filter, $body)';
}
