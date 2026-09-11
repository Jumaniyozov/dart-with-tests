import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:ch38_expenses/src/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

// #region counting
/// A [Store] that answers a thousand expenses and counts what that cost.
///
/// A **counting double**, which is neither of the two study 27 named. A fake
/// implements the behaviour and a mock asserts on calls; this implements the
/// behaviour *and* keeps a tally, because the claim being made is not about
/// what the program answered — it is about how much the store was asked to do
/// to answer it.
class CountingStore implements Store {
  int reads = 0;
  int handedOver = 0;

  @override
  Future<List<Expense>> get all async {
    reads++;
    final expenses = [
      for (var i = 0; i < 1000; i++)
        Expense(Money.fromPence(1), Category('food'), Day(2026, 9, 11), '$i'),
    ];
    handedOver += expenses.length;
    return expenses;
  }

  @override
  Future<void> record(Expense expense) async {}

  @override
  Future<List<Limit>> get limits async => const [];

  @override
  Future<void> setLimit(Limit limit) async {}
}
// #endregion counting

void main() {
  // #region harness
  const key = 'a-shared-key';
  final today = Day(2026, 9, 11);

  /// One request to the **whole edge** — the pipeline and the routes, not a
  /// bare handler. Every claim below is about what a stranger would get back.
  Future<Response> ask(
    Store store,
    String method,
    String path, {
    String? body,
    String? authorization = 'Bearer $key',
  }) async {
    final api = expensesApi(
      Tracker(store, () => today),
      key: key,
      report: (error, stack) {},
    );
    return await api(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {'authorization': ?authorization},
        body: body,
      ),
    );
  }

  /// The store study 37's transcripts are captured over: two expenses on food
  /// and a £20 limit on it.
  Future<Store> seeded() async {
    final store = InMemoryStore();
    await store.setLimit(Limit(Category('food'), Money.fromPence(2000)));
    await store.record(
      Expense(Money.fromPence(450), Category('food'), today, 'tea'),
    );
    await store.record(
      Expense(Money.fromPence(460), Category('food'), today, 'tea'),
    );
    return store;
  }
  // #endregion harness

  // #region routes
  group('every path the table has, and the two kinds it does not', () {
    test('GET /expenses is what study 36 answered everywhere', () async {
      final response = await ask(await seeded(), 'GET', '/expenses');

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), hasLength(2));
    });

    test('GET /budgets is a different document at a different path', () async {
      final response = await ask(await seeded(), 'GET', '/budgets');

      expect(jsonDecode(await response.readAsString()), [
        {'category': 'food', 'limit': 2000, 'spent': 910, 'remaining': 1090},
      ]);
    });

    test('GET /budgets/<category> is one of them, by name', () async {
      final response = await ask(await seeded(), 'GET', '/budgets/food');

      expect(response.statusCode, 200);
      expect((jsonDecode(await response.readAsString()) as Map)['spent'], 910);
    });

    test('a path the table has not got is the 404 Router gives away', () async {
      final response = await ask(await seeded(), 'GET', '/nowhere');

      expect(response.statusCode, 404);
    });

    test('and so is a verb it has not got at a path it has', () async {
      final response = await ask(await seeded(), 'POST', '/budgets');

      expect(
        response.statusCode,
        404,
        reason:
            'the verb is part of the key, and this router does not answer 405',
      );
    });

    test(
      "but the Router's own 404 is not a document, hence notFoundHandler",
      () async {
        final bare = Router()
          ..get('/expenses', (Request request) => Response.ok('x'));

        final response = await bare.call(
          Request('GET', Uri.parse('http://localhost/nowhere')),
        );

        expect(response.statusCode, 404);
        expect(await response.readAsString(), 'Route not found');
        expect(
          response.headers['content-type'],
          isNot(startsWith('application/json')),
          reason:
              'which would have been the one answer on this server that a '
              'caller could not parse the way it parses every other one',
        );
      },
    );
  });
  // #endregion routes

  // #region statuses
  group("study 26's taxonomy, with a wire under it", () {
    test('a request nobody signed is 401, whatever it asked for', () async {
      final response = await ask(
        await seeded(),
        'GET',
        '/expenses',
        authorization: null,
      );

      expect(response.statusCode, 401);
      expect(jsonDecode(await response.readAsString()), {
        'problem': 'who is asking?',
      });
    });

    test('a month nobody can read is 400 — the request is garbled', () async {
      final response = await ask(
        await seeded(),
        'GET',
        '/expenses?month=2026-13',
      );

      expect(response.statusCode, 400);
    });

    test('and so is a bound that is not a count', () async {
      for (final asked in ['0x10', '-1', ' 3', '3.0', 'many']) {
        final response = await ask(
          await seeded(),
          'GET',
          '/expenses?limit=$asked',
        );

        expect(
          response.statusCode,
          400,
          reason: 'int.tryParse would have read "$asked" more generously',
        );
      }
    });

    test('a budget that refuses is 409, and nothing was written', () async {
      final store = await seeded();

      final response = await ask(
        store,
        'POST',
        '/expenses',
        body: '{"pence":2000,"category":"food","note":"feast"}',
      );

      expect(response.statusCode, 409);
      expect(
        await store.all,
        hasLength(2),
        reason: 'a breach nobody acknowledged is a refusal, not a warning',
      );
    });

    test('and the refusal is money, not a sentence about money', () async {
      final response = await ask(
        await seeded(),
        'POST',
        '/expenses',
        body: '{"pence":2000,"category":"food","note":"feast"}',
      );

      expect(jsonDecode(await response.readAsString()), {
        'problem': 'over budget',
        'category': 'food',
        'limit': 2000,
        'over': 910,
      }, reason: 'study 36 owed the limit as data, and this is it');
    });

    test('an acknowledged breach is 200 and is kept', () async {
      final store = await seeded();

      final response = await ask(
        store,
        'POST',
        '/expenses',
        body:
            '{"pence":2000,"category":"food","note":"feast",'
            '"acknowledged":true}',
      );

      expect(response.statusCode, 200);
      expect(await store.all, hasLength(3));
    });

    test('a body that is not an expense is 400, and throws nothing', () async {
      for (final body in [
        '',
        'not json at all',
        '{"pence":"450","category":"food","note":"tea"}',
        '{"pence":-1,"category":"food","note":"tea"}',
        '{"pence":450,"category":"  ","note":"tea"}',
        '{"pence":450,"category":"food"}',
      ]) {
        final response = await ask(
          await seeded(),
          'POST',
          '/expenses',
          body: body,
        );

        expect(response.statusCode, 400, reason: 'over $body');
      }
    });

    test('a category with no limit on it is the other 404', () async {
      final response = await ask(await seeded(), 'GET', '/budgets/transport');

      expect(response.statusCode, 404);
      expect(jsonDecode(await response.readAsString()), {
        'problem': 'no budget on transport',
      });
    });

    test('every one of them is the same shape and says so', () async {
      for (final path in ['/nowhere', '/expenses?month=x', '/budgets/none']) {
        final response = await ask(await seeded(), 'GET', path);

        expect(
          response.headers['content-type'],
          startsWith('application/json'),
        );
        expect(jsonDecode(await response.readAsString()), contains('problem'));
      }
    });
  });
  // #endregion statuses

  // #region stranger
  group('what the router hands over is exactly what arrived', () {
    test(
      'a space is %20 here, and decoding it is this program\'s job',
      () async {
        final store = InMemoryStore();
        await store.setLimit(
          Limit(Category('food and drink'), Money.fromPence(2000)),
        );

        final response = await ask(store, 'GET', '/budgets/food%20and%20drink');

        expect(
          response.statusCode,
          200,
          reason: 'the command line can make that category, so it has a name',
        );
      },
    );

    test(
      'a segment that decodes to nothing is 400, not a thrown Error',
      () async {
        final response = await ask(await seeded(), 'GET', '/budgets/%20');

        expect(
          response.statusCode,
          400,
          reason:
              'Category throws for a blank name, and an Error is not caught',
        );
      },
    );

    test('and a malformed escape is a literal, not a 500', () async {
      final response = await ask(await seeded(), 'GET', '/budgets/%zz');

      expect(response.statusCode, 404);
      expect(jsonDecode(await response.readAsString()), {
        'problem': 'no budget on %zz',
      }, reason: 'Uri.parse wrote the stray % as %25 before the router saw it');
    });

    test('the pattern really does capture it undecoded', () async {
      late String captured;
      final bare = Router()
        ..get('/budgets/<category>', (Request request, String category) {
          captured = category;
          return Response.ok('');
        });

      await bare.call(
        Request(
          'GET',
          Uri.parse('http://localhost/budgets/food%20and%20drink'),
        ),
      );

      expect(captured, 'food%20and%20drink');
    });

    test('and the reason decoding cannot throw is two layers away', () {
      expect(
        () => Uri.decodeComponent('%zz'),
        throwsArgumentError,
        reason: 'so a segment reaching it malformed would be a 500',
      );
      expect(
        Uri.parse('http://localhost/budgets/%zz').path,
        '/budgets/%25zz',
        reason: 'and none ever does, because Uri.parse escapes the % first',
      );
    });

    test('int.tryParse is more generous than a sentence about it', () {
      expect(int.tryParse('0x10'), 16);
      expect(int.tryParse('+3'), 3);
      expect(int.tryParse('-1'), -1);
      expect(
        int.tryParse('99999999999999999999'),
        isNull,
        reason: 'and the one case where it is not generous is a run of digits',
      );
    });
  });
  // #endregion stranger

  // #region faults
  group('a thrown Error is a 500 the stranger must never read', () {
    test('one fixed sentence out, and everything else reported', () async {
      final reported = <Object>[];
      final handler = faults((error, stack) => reported.add(error))(
        (request) => throw StateError('expenses.txt is a directory'),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/expenses')),
      );
      final body = await response.readAsString();

      expect(response.statusCode, 500);
      expect(jsonDecode(body), {'problem': 'this program is wrong'});
      expect(body, isNot(contains('directory')));
      expect(
        reported.single.toString(),
        contains('expenses.txt is a directory'),
        reason:
            'the stranger learns that it failed and whoever can fix it learns '
            'why, which is the whole of the trade',
      );
    });

    test(
      'and shelf already refused to say more, with nothing wrapped',
      () async {
        final server = await io.serve(
          (request) => throw StateError('a path off somebody else machine'),
          'localhost',
          0,
        );
        addTearDown(() => server.close(force: true));

        final request = await HttpClient().getUrl(
          Uri.http('localhost:${server.port}', '/'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, 500);
        expect(
          body,
          'Internal Server Error',
          reason:
              'so the middleware above is about the shape of that answer and '
              'where the report goes, not about a leak that was never there',
        );
        expect(
          response.headers.contentType?.mimeType,
          isNot('application/json'),
          reason:
              'which is the one answer on this server that is not a document',
        );
      },
    );
  });
  // #endregion faults

  // #region key
  group('one shared key, and it is a caller that it authenticates', () {
    Handler guarded() =>
        onlyWithKey(key)((request) => Response.ok('through\n'));

    test('the right key goes through to the handler behind it', () async {
      final response = await guarded()(
        Request(
          'GET',
          Uri.parse('http://localhost/expenses'),
          headers: {'authorization': 'Bearer $key'},
        ),
      );

      expect(await response.readAsString(), 'through\n');
    });

    test('and no header, a wrong key or the bare key does not', () async {
      for (final sent in [null, 'Bearer wrong', key, 'Basic $key']) {
        final response = await guarded()(
          Request(
            'GET',
            Uri.parse('http://localhost/expenses'),
            headers: {'authorization': ?sent},
          ),
        );

        expect(response.statusCode, 401, reason: 'over ${sent ?? 'nothing'}');
      }
    });

    test('401 and not 403, because there is nobody to know about', () async {
      final response = await ask(
        await seeded(),
        'GET',
        '/expenses',
        authorization: 'Bearer wrong',
      );

      expect(
        response.statusCode,
        401,
        reason:
            '403 means I know who you are and the answer is still no, and '
            'CONTEXT.md says this program has no Account to know',
      );
    });
  });
  // #endregion key

  // #region clock
  group('what the edge files an expense under', () {
    const sending = 'a-shared-key';

    test('is the day the clock answers when the request arrives', () async {
      var day = Day(2026, 9, 8);
      final store = InMemoryStore();
      final api = expensesApi(
        Tracker(store, () => day),
        key: sending,
        report: (error, stack) {},
      );

      Future<void> post() async => await api(
        Request(
          'POST',
          Uri.parse('http://localhost/expenses'),
          headers: {'authorization': 'Bearer $sending'},
          body: '{"pence":450,"category":"food","note":"tea"}',
        ),
      );

      await post();
      day = Day(2026, 9, 11);
      await post();

      expect(
        [for (final expense in await store.all) expense.day],
        [Day(2026, 9, 8), Day(2026, 9, 11)],
        reason:
            'one server, one process, two days — which is the ordinary '
            'case for a server and never happens to a command',
      );
    });
  });
  // #endregion clock

  // #region bound
  group('the bound on list is cosmetic, and here is the measurement', () {
    test('one expense and a thousand cost the store the same', () async {
      final small = CountingStore();
      final large = CountingStore();

      final one = await ask(small, 'GET', '/expenses?limit=1');
      final thousand = await ask(large, 'GET', '/expenses?limit=1000');

      expect(jsonDecode(await one.readAsString()), hasLength(1));
      expect(jsonDecode(await thousand.readAsString()), hasLength(1000));

      expect([small.reads, small.handedOver], [1, 1000]);
      expect(
        [large.reads, large.handedOver],
        [small.reads, small.handedOver],
        reason:
            'the document got a thousand times smaller and the work did not '
            'move at all; study 39 is where a bound can be kept',
      );
    });
  });
  // #endregion bound

  // #region json
  group('why every amount on this wire is an integer number of pence', () {
    test('a JSON number with a point in it decodes to a double', () {
      expect(jsonDecode('20.10'), isA<double>());
      expect(jsonDecode('2010'), isA<int>());
    });

    test('and study 19 is what a double cannot hold', () {
      expect(0.1 + 0.2 == 0.3, isFalse);
      expect(Money.fromPence(10) + Money.fromPence(20), Money.fromPence(30));
    });
  });
  // #endregion json

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

    test(
      'and file_store.dart is still the only one that has heard of dart:io',
      () {
        final knowing = {
          for (final entity in Directory('lib/src').listSync())
            if (importsOf(entity.path).contains('dart:io'))
              entity.uri.pathSegments.last,
        };

        expect(
          knowing,
          {'file_store.dart'},
          reason:
              "that file's own doc comment says so, and study 38 is the study "
              'that could have made it a lie — a HoldingStore taking a File '
              'would not have shown up in either test above',
        );
      },
    );
  });
  // #endregion borrowed

  // #region returns
  group('shelf is dart:io plus a function type', () {
    test('so serve hands back the dart:io server it bound', () async {
      final server = await io.serve(
        expensesApi(
          Tracker(InMemoryStore(), () => today),
          key: key,
          report: (error, stack) {},
        ),
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
        expensesApi(
          Tracker(InMemoryStore(), () => today),
          key: key,
          report: (error, stack) {},
        ),
        'localhost',
        0,
        poweredByHeader: poweredBy,
      );
      try {
        final request = await HttpClient().getUrl(
          Uri.http('localhost:${server.port}', '/expenses'),
        );
        request.headers.set('authorization', 'Bearer $key');
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

      expect(headers['content-length'], '3', reason: 'an empty JSON list');
      expect(headers, isNot(contains('transfer-encoding')));
    });
  });
  // #endregion headers
}
