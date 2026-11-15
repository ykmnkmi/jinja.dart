@TestOn('vm')
library;

import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';
import 'package:test/test.dart';

// The expected output in `test/flaskr/expected` is rendered from the same
// templates by the reference Python Jinja2 implementation with default
// environment options, so whitespace handling is checked exactly.

const String templatesPath = 'test/flaskr/templates';

const String expectedPath = 'test/flaskr/expected';

Map<String, Object?> createdDate(int year, int month, int day) {
  var yyyy = year.toString().padLeft(4, '0');
  var mm = month.toString().padLeft(2, '0');
  var dd = day.toString().padLeft(2, '0');

  return <String, Object?>{
    'strftime': (String format) {
      return format
          .replaceAll('%Y', yyyy)
          .replaceAll('%m', mm)
          .replaceAll('%d', dd);
    },
  };
}

String urlFor(String endpoint, {String? filename, Object? id}) {
  return switch (endpoint) {
    'static' => '/static/$filename',
    'auth.register' => '/auth/register',
    'auth.login' => '/auth/login',
    'auth.logout' => '/auth/logout',
    'blog.index' => '/',
    'blog.create' => '/create',
    'blog.update' => '/$id/update',
    'blog.delete' => '/$id/delete',
    _ => throw ArgumentError.value(endpoint, 'endpoint'),
  };
}

String normalize(String text) {
  return text.replaceAll('\r\n', '\n');
}

typedef Case = ({
  String template,
  Map<String, Object?>? user,
  List<String> flashes,
  Map<String, String> form,
  Map<String, Object?> data,
});

void main() {
  var alice = <String, Object?>{'id': 1, 'username': 'test'};

  var posts = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'author_id': 1,
      'username': 'test',
      'title': 'test title',
      'body': 'test body',
      'created': createdDate(2018, 1, 1),
    },
    <String, Object?>{
      'id': 2,
      'author_id': 2,
      'username': 'other',
      'title': 'second title',
      'body': 'second body',
      'created': createdDate(2018, 1, 2),
    },
  ];

  var post = <String, Object?>{
    'id': 1,
    'author_id': 1,
    'title': 'test title',
    'body': 'test body',
  };

  var cases = <String, Case>{
    'register': (
      template: 'auth/register.html',
      user: null,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{},
    ),
    'login_flash': (
      template: 'auth/login.html',
      user: null,
      flashes: <String>['Incorrect username.'],
      form: <String, String>{},
      data: <String, Object?>{},
    ),
    'index_logged_out': (
      template: 'blog/index.html',
      user: null,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{'posts': posts},
    ),
    'index_logged_in': (
      template: 'blog/index.html',
      user: alice,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{'posts': posts},
    ),
    'index_empty': (
      template: 'blog/index.html',
      user: null,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{'posts': <Object?>[]},
    ),
    'create_blank': (
      template: 'blog/create.html',
      user: alice,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{},
    ),
    'create_repopulated': (
      template: 'blog/create.html',
      user: alice,
      flashes: <String>['Title is required.'],
      form: <String, String>{'title': '', 'body': 'Draft content'},
      data: <String, Object?>{},
    ),
    'update_existing': (
      template: 'blog/update.html',
      user: alice,
      flashes: <String>[],
      form: <String, String>{},
      data: <String, Object?>{'post': post},
    ),
    'update_override': (
      template: 'blog/update.html',
      user: alice,
      flashes: <String>[],
      form: <String, String>{'title': 'updated title', 'body': 'updated body'},
      data: <String, Object?>{'post': post},
    ),
  };

  for (var optimize in <bool>[true, false]) {
    group('Flaskr optimize=$optimize', () {
      for (var MapEntry(key: name, value: item) in cases.entries) {
        test(name, () {
          var env = Environment(
            loader: FileSystemLoader(paths: <String>[templatesPath]),
            optimize: optimize,
            globals: <String, Object?>{
              'url_for': urlFor,
              'get_flashed_messages': () => item.flashes,
              'g': <String, Object?>{'user': item.user},
              'request': <String, Object?>{'form': item.form},
            },
          );

          var actual = env.getTemplate(item.template).render(item.data);
          var expected = File('$expectedPath/$name.html').readAsStringSync();
          expect(normalize(actual), equals(normalize(expected)));
        });
      }
    });
  }
}
