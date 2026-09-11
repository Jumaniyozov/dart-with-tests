import 'package:ch36_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final today = Day(2026, 9, 11);

Expense spent(int pence, String category, {Day? on}) =>
    Expense(Money.fromPence(pence), Category(category), on ?? today, 'a note');

void main() {
  late Tracker tracker;
  setUp(() => tracker = Tracker(InMemoryStore(), today));

  group('challenge 1 — what was spent over a period', () {
    test('nothing recorded is nothing spent', () async {
      expect(await spentIn(tracker, Period.of(today)), Money.zero);
    });

    test('and everything inside the period, added up', () async {
      await tracker.record(spent(450, 'food'));
      await tracker.record(spent(320, 'transport'));

      expect(await spentIn(tracker, Period.of(today)), Money.fromPence(770));
    });

    test('and nothing outside it', () async {
      await tracker.record(spent(450, 'food', on: Day(2026, 8, 31)));
      await tracker.record(spent(320, 'food'));

      expect(await spentIn(tracker, Period.of(today)), Money.fromPence(320));
    });
  });

  group('challenge 2 — the same verdict, as one caller\'s exit code', () {
    test('no budget on the category is nothing standing in the way', () {
      expect(codeFor(null, acknowledged: false), okay);
    });

    test('and so is a verdict that fits', () {
      expect(codeFor(Within(Money.fromPence(500)), acknowledged: false), okay);
    });

    test('a breach nobody acknowledged is a refusal', () {
      expect(
        codeFor(Breach(Money.fromPence(500)), acknowledged: false),
        refused,
      );
    });

    test('and an acknowledged one is not', () {
      expect(codeFor(Breach(Money.fromPence(500)), acknowledged: true), okay);
    });
  });

  group('challenge 3 — which categories have gone past their limit', () {
    test('nothing set is nothing overspent', () async {
      expect(await overspent(tracker), isEmpty);
    });

    test('a category inside its limit is not overspent', () async {
      await tracker.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await tracker.record(spent(500, 'food'));

      expect(await overspent(tracker), isEmpty);
    });

    test('spending the limit exactly is not going past it', () async {
      await tracker.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await tracker.record(spent(2000, 'food'));

      expect(await overspent(tracker), isEmpty);
    });

    test(
      'and one that has is named, in the order the budgets came back',
      () async {
        await tracker.setLimit(Limit(Category('food'), Money.fromPence(1000)));
        await tracker.setLimit(
          Limit(Category('transport'), Money.fromPence(500)),
        );
        await tracker.record(
          Expense(
            Money.fromPence(1500),
            Category('food'),
            today,
            'feast',
            acknowledged: true,
          ),
        );
        await tracker.record(
          Expense(
            Money.fromPence(900),
            Category('transport'),
            today,
            'taxi',
            acknowledged: true,
          ),
        );

        expect(await overspent(tracker), [
          Category('food'),
          Category('transport'),
        ]);
      },
    );
  });
}
