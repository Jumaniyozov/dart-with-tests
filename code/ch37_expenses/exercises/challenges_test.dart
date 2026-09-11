import 'dart:convert';

import 'package:ch37_expenses/expenses.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final today = Day(2026, 9, 11);
final food = Limit(Category('food'), Money.fromPence(2000));

Request get(String path) => Request('GET', Uri.parse('http://localhost$path'));

void main() {
  late Tracker tracker;
  setUp(() => tracker = Tracker(InMemoryStore(), today));

  group('challenge 1 — the same verdict, as an HTTP status', () {
    test('no budget on the category is nothing standing in the way', () {
      expect(statusFor(null, acknowledged: false), 200);
    });

    test('and so is a verdict that fits', () {
      expect(statusFor(Within(Money.fromPence(500)), acknowledged: false), 200);
    });

    test('a breach nobody acknowledged is a conflict', () {
      expect(
        statusFor(Breach(Money.fromPence(500), food), acknowledged: false),
        409,
      );
    });

    test('and an acknowledged one is not', () {
      expect(
        statusFor(Breach(Money.fromPence(500), food), acknowledged: true),
        200,
      );
    });
  });

  group('challenge 2 — a request refused before anything reads it', () {
    Future<Response> through(Request request) async =>
        await onlyJson()((request) => Response.ok('handled'))(request);

    test('a GET goes through whatever it says', () async {
      expect(await (await through(get('/expenses'))).readAsString(), 'handled');
    });

    test('and a POST that says application/json does too', () async {
      final response = await through(
        Request(
          'POST',
          Uri.parse('http://localhost/expenses'),
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: '{}',
        ),
      );

      expect(await response.readAsString(), 'handled');
    });

    test('a POST that says something else is 415', () async {
      final response = await through(
        Request(
          'POST',
          Uri.parse('http://localhost/expenses'),
          headers: {'content-type': 'text/plain'},
          body: 'hello',
        ),
      );

      expect(response.statusCode, 415);
    });

    test('and so is a POST that says nothing at all', () async {
      final response = await through(
        Request('POST', Uri.parse('http://localhost/expenses'), body: 'hello'),
      );

      expect(response.statusCode, 415);
    });
  });

  group('challenge 3 — two routes, one of which is a trap', () {
    Future<Object?> documentAt(String path) async {
      final response = await budgetRoutes(tracker).call(get(path));
      return jsonDecode(await response.readAsString());
    }

    test('no limits set at all is a total of nothing', () async {
      expect(await documentAt('/budgets/total'), {'limit': 0});
    });

    test('and every limit added up, whatever they are on', () async {
      await tracker.setLimit(food);
      await tracker.setLimit(
        Limit(Category('transport'), Money.fromPence(500)),
      );

      expect(await documentAt('/budgets/total'), {'limit': 2500});
    });

    test('a category with a limit on it answers its own', () async {
      await tracker.setLimit(food);

      expect(await documentAt('/budgets/food'), {
        'category': 'food',
        'limit': 2000,
      });
    });

    test('and one without is 404', () async {
      final response = await budgetRoutes(tracker).call(get('/budgets/rent'));

      expect(response.statusCode, 404);
    });
  });
}
