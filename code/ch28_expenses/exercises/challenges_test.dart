import 'dart:io';

import 'package:ch28_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final day = Day(2026, 9, 9);

Expense expenseOf(int pence, String category, String note) =>
    Expense(Money.fromPence(pence), Category(category), day, note);

void main() {
  late Directory directory;
  late File source;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('challenges');
    source = File('${directory.path}/seed.txt');
  });
  tearDown(() => directory.delete(recursive: true));

  group('challenge 1 — a store seeded from a file', () {
    test('a source that is not there means nothing was seeded', () async {
      expect(await SeededStore(source).all, isEmpty);
    });

    test('reads what is in the file', () async {
      await source.writeAsString(
        '2026-09-09,1250,food,coffee\n2026-09-09,300,transport,bus\n',
      );
      final store = SeededStore(source);
      expect([for (final e in await store.all) e.note], ['coffee', 'bus']);
      expect(await store.totals, {
        Category('food'): Money.fromPence(1250),
        Category('transport'): Money.fromPence(300),
      });
    });

    test('keeps what it is told without writing it down', () async {
      await source.writeAsString('2026-09-09,1250,food,coffee\n');
      final store = SeededStore(source);
      await store.all;
      await store.record(expenseOf(250, 'food', 'soup'));

      expect([for (final e in await store.all) e.note], ['coffee', 'soup']);
      expect(
        await source.readAsString(),
        '2026-09-09,1250,food,coffee\n',
        reason: 'the file is a starting point, not a home',
      );
    });
  });

  group('challenge 2 — a sentence about the whole store', () {
    test('says so when there is nothing', () async {
      expect(await summarise(InMemoryStore()), 'nothing recorded yet');
    });

    test('counts one without an s', () async {
      final store = InMemoryStore();
      await store.record(expenseOf(1250, 'food', 'coffee'));
      expect(await summarise(store), '1 expense, £12.50 in total');
    });

    test('and adds the rest up', () async {
      final store = InMemoryStore();
      await store.record(expenseOf(1250, 'food', 'coffee'));
      await store.record(expenseOf(300, 'transport', 'bus'));
      await store.record(expenseOf(5, 'food', 'sweet'));
      expect(await summarise(store), '3 expenses, £15.55 in total');
    });
  });

  group('challenge 3 — a field that can hold a comma', () {
    test('a comma is escaped', () {
      expect(escapeField('bus, then train'), r'bus\, then train');
    });

    test('a backslash is escaped too', () {
      expect(escapeField(r'back\slash'), r'back\\slash');
    });

    test('and the pair survives anything, in either order', () {
      for (final text in [
        'plain',
        'bus, then train',
        r'back\slash',
        r'both\, at once',
        r'\,',
        r',\',
        '',
      ]) {
        expect(
          unescapeField(escapeField(text)),
          text,
          reason: 'round trip of "$text"',
        );
      }
    });

    test('an escaped field has no bare comma left in it', () {
      expect(escapeField('a,b,c').split(RegExp(r'(?<!\\),')), hasLength(1));
    });
  });
}
