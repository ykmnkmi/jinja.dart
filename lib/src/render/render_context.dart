import 'package:jinja/src/environment.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/runtime.dart';
import 'package:jinja/src/utils.dart';
import 'package:meta/dart2js.dart';

final class ParentTemplateRef {
  new([this.template]);

  Template? template;
}

base class RenderContext extends Context {
  new(
    super.environment,
    this.sink, {
    super.template,
    super.blocks,
    Map<String, Object?>? globals,
    Namespace? self,
    ParentTemplateRef? parentTemplateRef,
    this.callerContext,
    super.parent,
    super.data,
  }) : globals = globals ?? parent,
       self = self ?? Namespace(),
       _parentTemplateRef = parentTemplateRef ?? ParentTemplateRef();

  final StringSink sink;

  final Map<String, Object?> globals;

  final Namespace self;

  final ParentTemplateRef _parentTemplateRef;

  final RenderContext? callerContext;

  Template? get parentTemplate => _parentTemplateRef.template;

  set parentTemplate(Template? value) {
    _parentTemplateRef.template = value;
  }

  void assignTargets(Object? target, Object? current) {
    if (target is String) {
      set(target, current);
    } else if (target is List<Object?>) {
      var values = list(current);

      if (values.length < target.length) {
        throw StateError('Not enough values to unpack.');
      }

      if (values.length > target.length) {
        throw StateError('Too many values to unpack.');
      }

      for (var i = 0; i < target.length; i++) {
        assignTargets(target[i], values[i]);
      }
    } else if (target is NamespaceValue) {
      var value = resolve(target.name);

      if (value is! Namespace) {
        throw TemplateRuntimeError('Non-namespace object.');
      }

      value[target.item] = current;
    } else {
      throw TypeError();
    }
  }

  Map<String, Object?> getDataForTargets(Object? targets, Object? current) {
    if (targets is String) {
      return <String, Object?>{targets: current};
    }

    if (targets is List<Object?>) {
      var values = list(current);

      if (values.length < targets.length) {
        throw StateError(
          'Not enough values to unpack (expected ${targets.length}, '
          'got ${values.length}).',
        );
      }

      if (values.length > targets.length) {
        throw StateError(
          'Too many values to unpack (expected ${targets.length}).',
        );
      }

      var result = <String, Object?>{};

      for (var i = 0; i < targets.length; i++) {
        var target = targets[i];

        if (target is String) {
          result[target] = values[i];
        } else {
          result.addAll(getDataForTargets(target, values[i]));
        }
      }

      return result;
    }

    throw ArgumentError.value(targets, 'targets');
  }

  @override
  RenderContext derived({
    StringSink? sink,
    String? template,
    Map<String, Object?>? data,
    RenderContext? callerContext,
    bool withContext = true,
  }) {
    Map<String, Object?> parent;

    if (withContext) {
      parent = <String, Object?>{
        ...this.parent,
        ...?this.callerContext?.parent,
        ...?this.callerContext?.context,
        ...context,
      };
    } else {
      parent = globals;
      data = null;
    }

    return RenderContext(
      environment,
      sink ?? this.sink,
      template: template ?? this.template,
      blocks: blocks,
      globals: globals,
      self: self,
      parentTemplateRef: _parentTemplateRef,
      callerContext: callerContext ?? this.callerContext,
      parent: parent,
      data: data,
    );
  }

  Object? finalize(Object? object) {
    return environment.finalize(this, object);
  }

  @noInline
  void write(Object? value) {
    sink.write(value);
  }
}
