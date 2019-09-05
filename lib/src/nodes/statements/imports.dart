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
    Template template;

    final oneOrList = paths.resolve(context);

    if (oneOrList is List) {
      for (var path in oneOrList) {
        if (path is String) {
          template = context.env.templates[path];
        } else if (path is Template) {
          template = path;
        }

        if (template != null) break;
      }
    } else if (oneOrList is String) {
      template = context.env.templates[oneOrList];
    } else if (oneOrList is Template) {
      template = oneOrList;
    }

    if (template != null) {
      if (withContext) {
        template.accept(buffer, context);
      } else {
        final newContext = Context(env: context.env);
        template.accept(buffer, newContext);
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
