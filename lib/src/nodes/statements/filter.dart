import '../../context.dart';
import '../../parser.dart';
import '../core.dart';
import '../expressions/filter.dart';

class FilterBlockStatement extends Statement {
  static FilterBlockStatement parse(Parser parser) {
    final endFilterReg = parser.getBlockEndRegFor('endfilter');

    if (parser.scanner.matches(parser.blockEndReg)) {
      parser.error('filter expected');
    }

    final filter = parser.parseFilter(hasLeadingPipe: false);

    if (filter is! Filter) {
      parser.error('filter expected but got ${filter.runtimeType}');
    }

    parser.scanner.expect(parser.blockEndReg);

    final body = parser.parseStatements([endFilterReg]);

    parser.scanner.expect(endFilterReg);

    return FilterBlockStatement(filter, body);
  }

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
