import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ch36_expenses/expenses.dart';
import 'package:ch36_expenses/src/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

void main() {
  // #region calling
  group('what the server can say now that it has the use cases', () {
    /// One request to a handler, with no server between the two.
    Future<Response> answer(Store store, {String path = '/'}) async =>
        await expensesHandler(Tracker(store, Day(2026, 9, 11)))(
          Request('GET', Uri.http('localhost', path)),
        );

    test('nothing recorded is an empty list, not an empty body', () async {
      final response = await answer(InMemoryStore());

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), isEmpty);
    });

    test('and the expenses, in the shape the file already writes', () async {
      final store = InMemoryStore();
      await store.record(
        Expense(
          Money.fromPence(450),
          Category('food'),
          Day(2026, 9, 11),
          'tea',
        ),
      );

      final response = await answer(store);

      expect(jsonDecode(await response.readAsString()), [
        {'day': '2026-09-11', 'pence': 450, 'category': 'food', 'note': 'tea'},
      ], reason: 'study 29 wrote this for a file; nothing re-invented it here');
    });

    test('as application/json, which is a claim about the bytes', () async {
      final response = await answer(InMemoryStore());

      expect(response.headers['content-type'], startsWith('application/json'));
    });

    test('at every path, because nothing here routes yet', () async {
      final response = await answer(InMemoryStore(), path: '/budgets');

      expect(response.statusCode, 200);
    });
  });
  // #endregion calling

  // #region borrowed
  group('which file has heard of what', () {
    /// Only the `import` lines. A doc comment naming a type is prose, and the
    /// claim here is about what a file depends on — `check_shown` discounts
    /// comments for the same reason.
    Set<String> importsOf(String path) => {
      for (final line in File(path).readAsLinesSync())
        if (RegExp(r"^import '(.+)';").firstMatch(line) case final match?)
          match.group(1)!,
    };

    test('the server does not import command.dart, and could not use it', () {
      expect(importsOf('lib/src/server.dart'), isNot(contains('command.dart')));
    });

    test('and the application layer imports no shelf and no dart:io', () {
      expect(
        importsOf('lib/src/tracker.dart').where(
          (uri) => uri.startsWith('package:shelf') || uri.startsWith('dart:io'),
        ),
        isEmpty,
        reason: 'a layer that names the edge it was extracted for is not one',
      );
    });
  });
  // #endregion borrowed

  // #region returns
  group('shelf is dart:io plus a function type', () {
    test('so serve hands back the dart:io server it bound', () async {
      final server = await io.serve(
        expensesHandler(Tracker(InMemoryStore(), Day(2026, 9, 11))),
        'localhost',
        0,
      );
      addTearDown(() => server.close(force: true));

      expect(server, isA<HttpServer>());
      expect(
        server,
        isA<Stream<HttpRequest>>(),
        reason: 'which is what makes a hand-rolled server an await for',
      );
      expect(server.port, greaterThan(0), reason: 'the port it really bound');
    });
  });
  // #endregion returns

  // #region headers
  group('what serve puts on the wire that the handler never said', () {
    /// Every header a real `serve` put on a real response, by name.
    ///
    /// A real socket, because this is the one claim in the file that is about
    /// what reaches the wire rather than about what the handler returned.
    Future<Map<String, String>> headersFrom({
      required String? poweredBy,
    }) async {
      final server = await io.serve(
        expensesHandler(Tracker(InMemoryStore(), Day(2026, 9, 11))),
        'localhost',
        0,
        poweredByHeader: poweredBy,
      );
      try {
        final request = await HttpClient().getUrl(
          Uri.http('localhost:${server.port}', '/'),
        );
        final response = await request.close();
        await response.drain<void>();
        final sent = <String, String>{};
        response.headers.forEach((name, values) => sent[name] = values.single);
        return sent;
      } finally {
        await server.close(force: true);
      }
    }

    test("three of them are dart:io's, not shelf's", () async {
      final headers = await headersFrom(poweredBy: null);

      expect(
        headers.keys,
        containsAll([
          'x-frame-options',
          'x-xss-protection',
          'x-content-type-options',
        ]),
      );
    });

    test('a date and a name for itself', () async {
      final headers = await headersFrom(poweredBy: 'Dart with package:shelf');

      expect(headers, contains('date'));
      expect(headers['x-powered-by'], 'Dart with package:shelf');
    });

    test(
      'and poweredByHeader: null drops the second and nothing else',
      () async {
        final named = await headersFrom(poweredBy: 'Dart with package:shelf');
        final anonymous = await headersFrom(poweredBy: null);

        expect(anonymous, isNot(contains('x-powered-by')));
        expect(named.keys.toSet().difference(anonymous.keys.toSet()), {
          'x-powered-by',
        });
      },
    );

    test('and content-length, which the handler did not compute', () async {
      final headers = await headersFrom(poweredBy: null);

      expect(headers['content-length'], '2', reason: 'an empty JSON list');
      expect(headers, isNot(contains('transfer-encoding')));
    });
  });
  // #endregion headers
}
