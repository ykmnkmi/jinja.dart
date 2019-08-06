import 'env.dart';
import 'nodes.dart';

/// The template context holds the variables of a template.
///
/// It stores the values passed to the template.
/// Creating instances is neither supported nor useful as it's created
/// automatically at various stages of the template evaluation and should not
/// be created by hand.
class Context {
  Context(this.env,
      {Map<String, dynamic> data = const <String, dynamic>{},
      Map<String, Block> blocks = const <String, Block>{}})
      : data = Map<String, dynamic>.of(env.globals)..addAll(data),
        blocks = Map<String, Block>.of(blocks);

  /// Current environment.
  final Environment env;

  /// Passed variables to render.
  final Map<String, dynamic> data;

  /// Current extended blocks.
  final Map<String, Block> blocks;

  /// Get value by key or if it's not defined get `Undefined()` from env
  get(String key) => data[key] ?? env.undefined;

  /// Creates a copy of this context but with the given fields replaced
  /// with the new values.
  Context copyWith(
          {Map<String, dynamic> data = const <String, dynamic>{},
          Map<String, Block> blocks = const <String, Block>{},
          bool replace = false}) =>
      replace
          ? Context(env,
              data: Map<String, dynamic>.of(data),
              blocks: Map<String, Block>.of(blocks))
          : Context(env,
              data: Map<String, dynamic>.of(this.data)..addAll(data),
              blocks: Map<String, Block>.of(this.blocks)..addAll(blocks));

  @override
  String toString() => 'Context($data, $blocks)';
}

/// A loop context for loop iteration.
class LoopContext {
  const LoopContext(
      this.length, this.index0, this.previtem, this.nextitem, this.changed);

  /// The number of items in the sequence.
  final int length;

  /// The current iteration of the loop (0 indexed).
  final int index0;

  /// The current iteration of the loop (1 indexed).
  int get index => index0 + 1;

  /// The number of iterations from the end of the loop (1 indexed).
  int get revindex => length - index0;

  /// The number of iterations from the end of the loop (0 indexed).
  int get revindex0 => length - index;

  /// `true` if first iteration.
  bool get first => index0 == 0;

  /// `true` if last iteration.
  bool get last => index0 == length - 1;

  /// Indicates how deep in a recursive loop the rendering currently is.
  /// Starts at level 0.
  int get depth0 => 0;

  /// Indicates how deep in a recursive loop the rendering currently is.
  /// Starts at level 1.
  int get depth => depth + 1;

  /// The item from the previous iteration of the loop.
  /// Undefined during the first iteration.
  final previtem;

  /// The item from the following iteration of the loop.
  /// Undefined during the last iteration.
  final nextitem;

  /// `true` if previously called with a different value (or not called at all).
  final bool Function(dynamic) changed;

  /// A helper function to cycle between arguments.
  cycle(arg, arg2, [arg3, arg4, arg5, arg6, arg7, arg8, arg9]) {
    final args = [arg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
        .where((arg) => arg != null);
    return cycleIterable(args);
  }

  /// A helper function to cycle between elements in sequence.
  dynamic cycleIterable(Iterable iterable) =>
      iterable.elementAt(index0 % iterable.length);

  @override
  String toString() => 'LoopContext($length, $index0, $previtem, $nextitem, '
      '$changed)';
}

class RecursiveLoopContext extends LoopContext {
  const RecursiveLoopContext(this.caller, int length, int index0, previtem,
      nextitem, bool Function(dynamic) changed)
      : super(length, index0, previtem, nextitem, changed);

  final String Function(dynamic) caller;

  String call(value) => caller(value);

  @override
  String toString() => 'RecursiveLoopContext($caller, $length, $index0, '
      '$previtem, $nextitem, $changed)';
}
