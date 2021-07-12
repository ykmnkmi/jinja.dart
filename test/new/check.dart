// ignore_for_file: avoid_print

import 'package:jinja/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    var environment = Environment(
      loader: MapLoader({
        'a': '{{ self.intro() }}{% block intro %}BLOCK{% endblock %}'
            '{{ self.intro() }}',
        'b': '{% extends "a" %}{% block intro %}*{{ super() }}*{% endblock %}',
        'c': '{% extends "b" %}{% block intro %}-{{ super() }}-{% endblock %}',
      }),
    );

    final template = environment.getTemplate('c');
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
