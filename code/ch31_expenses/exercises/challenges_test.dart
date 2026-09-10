import 'package:ch31_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

Expense spent(int pence, String category, {Day? on, String note = 'x'}) =>
    Expense(
      Money.fromPence(pence),
      Category(category),
      on ?? Day(2026, 9, 9),
      note,
    );

void main() {
  group('challenge 1 — the dearest expense', () {
    test('is the one that cost the most', () {
      expect(
        dearest([
          spent(100, 'food', note: 'apple'),
          spent(900, 'rent', note: 'room'),
          spent(300, 'transport', note: 'bus'),
        ])?.note,
        'room',
      );
    });

    test('and nothing at all when there were none', () {
      expect(dearest([]), isNull);
    });

    test('with ties going to the earlier day', () {
      expect(
        dearest([
          spent(500, 'food', on: Day(2026, 9, 20), note: 'later'),
          spent(500, 'food', on: Day(2026, 9, 2), note: 'earlier'),
        ])?.note,
        'earlier',
      );
    });

    test('and one expense is its own dearest', () {
      final only = spent(1, 'food', note: 'penny');
      expect(dearest([only]), same(only));
    });
  });

  group('challenge 2 — a comparator somebody else chose', () {
    final cheapFood = CategoryTotal(Category('food'), Money.fromPence(100));
    final dearFood = CategoryTotal(Category('food'), Money.fromPence(900));
    final rent = CategoryTotal(Category('rent'), Money.fromPence(500));

    test('orders by name first', () {
      expect(byNameThenAmount(cheapFood, rent), isNegative);
      expect(byNameThenAmount(rent, cheapFood), isPositive);
    });

    test('then by amount, cheaper first', () {
      expect(byNameThenAmount(cheapFood, dearFood), isNegative);
      expect(byNameThenAmount(dearFood, cheapFood), isPositive);
    });

    test('and sorts a list into that order', () {
      final lines = [dearFood, rent, cheapFood]..sort(byNameThenAmount);
      expect(lines, [cheapFood, dearFood, rent]);
    });

    test('returning 0 only for lines that really are the same', () {
      expect(byNameThenAmount(cheapFood, cheapFood), isZero);
      expect(
        byNameThenAmount(
          cheapFood,
          CategoryTotal(Category('food'), Money.fromPence(100)),
        ),
        isZero,
      );
      expect(byNameThenAmount(cheapFood, rent), isNot(0));
      expect(byNameThenAmount(cheapFood, dearFood), isNot(0));
    });
  });

  group('challenge 3 — where the money went', () {
    test('as whole percents of the total', () {
      final report = Report.of([spent(350, 'food'), spent(650, 'rent')]);
      expect(shareOfSpending(report), {
        Category('food'): 35,
        Category('rent'): 65,
      });
    });

    test('rounded down, so they need not add up to a hundred', () {
      final report = Report.of([
        spent(100, 'food'),
        spent(100, 'rent'),
        spent(100, 'transport'),
      ]);
      expect(shareOfSpending(report).values, everyElement(33));
    });

    test('and an empty report divides by nothing', () {
      expect(shareOfSpending(Report.of([])), isEmpty);
    });

    test('one category takes all of it', () {
      expect(shareOfSpending(Report.of([spent(999, 'food')])), {
        Category('food'): 100,
      });
    });
  });
}
