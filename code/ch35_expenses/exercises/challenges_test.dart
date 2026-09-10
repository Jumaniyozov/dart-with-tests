import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'challenges.dart';

/// What to answer when no route matched.
Response missing(Request request) => Response.notFound('no such path');

/// One request, built by hand. No server, no port, no socket.
Request request(String path, {String method = 'GET'}) =>
    Request(method, Uri.http('localhost', path));

void main() {
  group('challenge 1 — a handler that always says the same thing', () {
    test('it answers 200 with the body it was given', () async {
      final response = await always('recorded: 3\n')(request('/'));

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'recorded: 3\n');
    });

    test(
      'at every path and for every method, because nothing routes',
      () async {
        final handler = always('hello');

        expect(
          await (await handler(request('/anything/at/all'))).readAsString(),
          'hello',
        );
        expect((await handler(request('/', method: 'POST'))).statusCode, 200);
      },
    );
  });

  group('challenge 2 — routing, by hand', () {
    /// Built inside each test rather than beside them: `always` throws until
    /// challenge 1 is done, and a group whose setup throws takes the whole file
    /// down instead of failing one test at a time.
    Handler routed() => byPath({
      '': always('the root'),
      'expenses': always('the expenses'),
    }, otherwise: missing);

    test(
      'the empty path is the root, because Request.url is relative',
      () async {
        final handler = routed();

        expect(await (await handler(request('/'))).readAsString(), 'the root');
      },
    );

    test(
      'and a named path reaches the handler that was named with it',
      () async {
        final handler = routed();

        expect(
          await (await handler(request('/expenses'))).readAsString(),
          'the expenses',
        );
      },
    );

    test(
      'and anything else falls to the handler that was given for it',
      () async {
        final handler = routed();

        final response = await handler(request('/budgets'));

        expect(response.statusCode, 404);
        expect(await response.readAsString(), 'no such path');
      },
    );
  });

  group('challenge 3 — a handler that wraps a handler', () {
    test('a GET reaches the handler inside, untouched', () async {
      final response = await onlyGet(always('recorded: 3\n'))(request('/'));

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'recorded: 3\n');
    });

    test(
      'and anything else is 405, with the method that would have worked',
      () async {
        final handler = onlyGet(always('recorded: 3\n'));

        final response = await handler(request('/', method: 'POST'));

        expect(response.statusCode, 405);
        expect(response.headers['allow'], 'GET');
      },
    );

    test('and the handler inside is never asked', () async {
      var asked = false;
      final handler = onlyGet((Request request) {
        asked = true;
        return Response.ok('');
      });

      await handler(request('/', method: 'DELETE'));

      expect(
        asked,
        isFalse,
        reason: 'a refused method is refused before it costs anything',
      );
    });
  });
}
