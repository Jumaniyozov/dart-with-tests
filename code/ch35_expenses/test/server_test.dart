import 'dart:async';
import 'dart:io';

import 'package:ch35_expenses/expenses.dart';
import 'package:ch35_expenses/src/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

void main() {
  // #region calling
  group('a handler is a function', () {
    test('so a test calls it, with no socket and no port', () async {
      final handler = expensesHandler(InMemoryStore());

      final response = await handler(
        Request('GET', Uri.http('localhost', '/')),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'recorded: 0\n');
    });

    test('and it answers with what the store holds', () async {
      final store = InMemoryStore();
      await store.record(
        Expense(
          Money.fromPence(450),
          Category('food'),
          Day(2026, 9, 11),
          'tea',
        ),
      );

      final response = await handler(store, '/');

      expect(await response.readAsString(), 'recorded: 1\n');
    });

    test('at every path, because nothing here routes', () async {
      final response = await handler(InMemoryStore(), '/anything/at/all');

      expect(response.statusCode, 200);
    });
  });
  // #endregion calling

  // #region returns
  group('shelf is dart:io plus a function type', () {
    test('so serve hands back the dart:io server it bound', () async {
      final server = await io.serve(
        expensesHandler(InMemoryStore()),
        'localhost',
        0,
      );
      addTearDown(() => server.close(force: true));

      expect(server, isA<HttpServer>());
      expect(
        server,
        isA<Stream<HttpRequest>>(),
        reason: 'which is what makes the loop in bin/by_hand.dart an await for',
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
        expensesHandler(InMemoryStore()),
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

    test('three of them are dart:io\'s, not shelf\'s', () async {
      final headers = await headersFrom(poweredBy: null);

      expect(
        headers.keys,
        containsAll([
          'x-frame-options',
          'x-xss-protection',
          'x-content-type-options',
        ]),
        reason: 'bin/by_hand.dart sends the same three, with no shelf anywhere',
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

      expect(headers['content-length'], '12');
      expect(headers, isNot(contains('transfer-encoding')));
    });
  });
  // #endregion headers

  // #region length
  group('who works out how long the body is', () {
    /// One response from a bare `HttpServer`, with no `shelf` anywhere.
    ///
    /// The claim in 35.1 is about `dart:io` rather than about this package, so
    /// it is measured against `dart:io` directly: the same handler written two
    /// ways, differing in one line.
    Future<HttpHeaders> rawHeaders({required bool sayingHowLong}) async {
      final server = await HttpServer.bind('localhost', 0);
      unawaited(
        server.first.then((request) async {
          const body = 'recorded: 0\n';
          if (sayingHowLong) request.response.contentLength = body.length;
          request.response.write(body);
          await request.response.close();
        }),
      );
      try {
        final request = await HttpClient().getUrl(
          Uri.http('localhost:${server.port}', '/'),
        );
        final response = await request.close();
        await response.drain<void>();
        return response.headers;
      } finally {
        await server.close(force: true);
      }
    }

    test('say nothing and dart:io chunks the body', () async {
      final headers = await rawHeaders(sayingHowLong: false);

      expect(headers.value('transfer-encoding'), 'chunked');
      expect(headers.contentLength, -1);
    });

    test('set contentLength and it sends content-length instead', () async {
      final headers = await rawHeaders(sayingHowLong: true);

      expect(headers.contentLength, 12);
      expect(headers.value('transfer-encoding'), isNull);
    });
  });
  // #endregion length

  // #region counting
  group('what the dependency costs, counted rather than remembered', () {
    /// Lines that are neither blank nor wholly a `//` comment.
    int code(String path) =>
        File(path)
            .readAsLinesSync()
            .where((line) => !RegExp(r'^\s*(//.*)?$').hasMatch(line))
            .length;

    test('the same server costs the same number of lines either way', () {
      final byHand = code('bin/by_hand.dart');
      final withShelf = code('lib/src/server.dart') + code('bin/serve.dart');

      expect(byHand, 15);
      expect(withShelf, byHand);
    });

    test('and the difference is which of them a test can call', () {
      expect(code('lib/src/server.dart'), 6);
    });
  });
  // #endregion counting
}

/// One request to a handler, with no server between the two.
Future<Response> handler(Store store, String path) async =>
    await expensesHandler(store)(Request('GET', Uri.http('localhost', path)));
