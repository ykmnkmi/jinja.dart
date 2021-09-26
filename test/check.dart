// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final env = Environment(
      loader: MapLoader({
        'a': '{% if false %}{% block x %}A{% endblock %}{% endif %}'
            '{{ self.x() }}',
        'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
      }),
    );

    final tmpl = env.getTemplate('b');
    print(tmpl.nodes);
    print(tmpl.blocks);
    print(tmpl.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace, terse: true));
  }
}
