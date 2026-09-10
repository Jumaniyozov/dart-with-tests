import 'package:ch32_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final september = Period(2026, 9);

Expense spent(int pence, {String category = 'food', String note = 'x'}) =>
    Expense(Money.fromPence(pence), Category(category), Day(2026, 9, 9), note);

Budget budget(String category, int limitPence, List<Expense> expenses) =>
    Budget.of(
      Limit(Category(category), Money.fromPence(limitPence)),
      september,
      expenses,
    );

void main() {
  group('challenge 1 — the budgets that are broken', () {
    test('is empty when nothing is over', () {
      expect(broken([]), isEmpty);
      expect(
        broken([
          budget('food', 2000, [spent(1999)]),
        ]),
        isEmpty,
      );
    });

    test('spending the limit exactly is not breaking it', () {
      expect(
        broken([
          budget('food', 2000, [spent(2000)]),
        ]),
        isEmpty,
      );
    });

    test('and finds the one that is over', () {
      final over = budget('food', 2000, [spent(2001)]);
      expect(broken([over]), [same(over)]);
    });

    test('worst first, measured in pence', () {
      final small = budget('food', 2000, [spent(2100)]);
      final large = budget('rent', 50000, [spent(55000, category: 'rent')]);
      expect(broken([small, large]), [same(large), same(small)]);
    });

    test('and unbroken budgets are left out entirely', () {
      final over = budget('food', 2000, [spent(2500)]);
      final fine = budget('rent', 50000, [spent(100, category: 'rent')]);
      expect(broken([fine, over, budget('travel', 100, [])]), [same(over)]);
    });

    test('ties go to the category name', () {
      final rent = budget('rent', 2000, [spent(2500, category: 'rent')]);
      final food = budget('food', 2000, [spent(2500)]);
      expect(
        [
          for (final b in broken([rent, food])) b.category.name,
        ],
        ['food', 'rent'],
      );
    });
  });

  group('challenge 2 — all of them at once', () {
    test('several expenses are one verdict', () {
      final food = budget('food', 2000, []);
      final verdict = afterAll(food, [spent(800), spent(800), spent(800)]);
      expect(verdict, isA<Breach>());
      expect((verdict as Breach).over, Money.fromPence(400));
    });

    test('and they fit when they fit', () {
      final food = budget('food', 2000, []);
      final verdict = afterAll(food, [spent(800), spent(800)]);
      expect((verdict as Within).remaining, Money.fromPence(400));
    });

    test('none of them is the budget as it stands', () {
      final food = budget('food', 2000, [spent(1500)]);
      expect((afterAll(food, []) as Within).remaining, Money.fromPence(500));
    });

    test('and an already-broken budget stays broken', () {
      final food = budget('food', 2000, [spent(2500)]);
      expect((afterAll(food, []) as Breach).over, Money.fromPence(500));
    });

    test('landing exactly on the limit is Within, not Breach', () {
      final food = budget('food', 2000, [spent(1200)]);
      final verdict = afterAll(food, [spent(800)]);
      expect(verdict, isA<Within>());
      expect((verdict as Within).remaining, Money.zero);
    });
  });

  group('challenge 3 — a rule that needs nothing else', () {
    test('a big round number is suspicious', () {
      expect(isSuspicious(spent(100000)), isTrue);
      expect(isSuspicious(spent(99999)), isFalse);
    });

    test('and so is a note with nothing in it', () {
      expect(isSuspicious(spent(100, note: '')), isTrue);
      expect(isSuspicious(spent(100, note: '   ')), isTrue);
      expect(isSuspicious(spent(100, note: 'lunch')), isFalse);
    });

    test('and it consults nothing but the expense', () {
      expect(isSuspicious(spent(500, category: 'rent')), isFalse);
      expect(isSuspicious(spent(500, category: 'food')), isFalse);
    });
  });
}
