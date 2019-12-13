import '../../context.dart';
import '../../environment.dart';
import '../../exceptions.dart';
import '../core.dart';

class IncludeStatement extends Statement {
  IncludeStatement(
    this.paths, {
    this.ignoreMissing = false,
    this.withContext = true,
  });

  final Expression paths;
  final bool ignoreMissing;
  final bool withContext;

  @override
  void accept(StringBuffer buffer, Context context) {
    final oneOrList = paths.resolve(context);
    Template template;

    if (oneOrList is List) {
      for (final path in oneOrList) {
        if (path is String) {
          template = context.environment.templates[path];
        } else if (path is Template) {
          template = path;
        }

        if (template != null) break;
      }
    } else if (oneOrList is String) {
      template = context.environment.templates[oneOrList];
    } else if (oneOrList is Template) {
      template = oneOrList;
    }

    if (template != null) {
      if (withContext) {
        template.accept(buffer, context);
      } else {
        template.accept(buffer, Context(env: context.environment));
      }
    } else if (!ignoreMissing) {
      throw TemplatesNotFound();
    }
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('inlcude ${paths.toDebugString()}');
    if (!withContext) buffer.write(' without context');
    if (ignoreMissing) buffer.write(' ignore missing');
    return buffer.toString();
  }

  @override
  String toString() => 'Include($paths)';
}
