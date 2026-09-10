import 'package:ch33_expenses/expenses.dart';
import 'package:test/test.dart';

// #region fixtures
final september = Period(2026, 9);
final food = Limit(Category('food'), Money.fromPence(20000));

Expense spent(int pence, {String category = 'food', Day? on}) => Expense(
  Money.fromPence(pence),
  Category(category),
  on ?? Day(2026, 9, 9),
  'x',
);

Budget budgetOver(List<Expense> expenses) =>
    Budget.of(food, september, expenses);
// #endregion fixtures

void main() {
  // #region gathering
  group('a budget gathers exactly what the rule needs', () {
    test('the expenses in its category and its period', () {
      final budget = budgetOver([
        spent(1000),
        spent(2000),
        spent(500, category: 'transport'),
        spent(9900, on: Day(2026, 8, 31)),
        spent(9900, on: Day(2026, 10, 1)),
      ]);
      expect(budget.spent, Money.fromPence(3000));
      expect(budget.counted, hasLength(2));
    });

    test('and nothing else in the store has any bearing on it', () {
      final onlyOthers = budgetOver([
        spent(50000, category: 'rent'),
        spent(50000, on: Day(2025, 9, 9)),
      ]);
      expect(onlyOthers.spent, Money.zero);
      expect(onlyOthers.remaining, food.amount);
    });

    test('an empty month has all of it left', () {
      expect(budgetOver([]).remaining, Money.fromPence(20000));
      expect(budgetOver([]).isBroken, isFalse);
    });
  });
  // #endregion gathering

  // #region partial
  group('what is left, when there is such a thing', () {
    test('is the limit minus what went out', () {
      expect(budgetOver([spent(7500)]).remaining, Money.fromPence(12500));
    });

    test('and exactly nothing at the limit, which is not the same as null', () {
      final budget = budgetOver([spent(20000)]);
      expect(budget.remaining, Money.zero);
      expect(budget.isBroken, isFalse, reason: 'spending it all is allowed');
    });

    test('and null past it, because no Money means overspent', () {
      final budget = budgetOver([spent(20001)]);
      expect(budget.remaining, isNull);
      expect(budget.isBroken, isTrue);
    });

    test('which is Money.operator- refusing to invent an answer', () {
      expect(Money.fromPence(500) - Money.fromPence(200), Money.fromPence(300));
      expect(Money.fromPence(500) - Money.fromPence(500), Money.zero);
      expect(Money.fromPence(500) - Money.fromPence(501), isNull);
    });

    test('and + never needs to, because it cannot fail', () {
      expect(
        Money.fromPence(500) + Money.fromPence(200),
        isA<Money>(),
        reason: 'the return types are the difference between the two',
      );
    });
  });
  // #endregion partial

  // #region verdict
  group('the verdict on one more expense', () {
    test('fits, and says what would be left', () {
      final verdict = budgetOver([spent(15000)]).on(spent(2000));
      expect(verdict, isA<Within>());
      expect((verdict as Within).remaining, Money.fromPence(3000));
    });

    test('fits exactly, which still fits', () {
      final verdict = budgetOver([spent(15000)]).on(spent(5000));
      expect(verdict, isA<Within>());
      expect((verdict as Within).remaining, Money.zero);
    });

    test('does not fit, and says by how much', () {
      final verdict = budgetOver([spent(15000)]).on(spent(6000));
      expect(verdict, isA<Breach>());
      expect((verdict as Breach).over, Money.fromPence(1000));
    });

    test('and an expense on its own can break it', () {
      final verdict = budgetOver([]).on(spent(20001));
      expect((verdict as Breach).over, Money.fromPence(1));
    });

    test('the switch over it is checked for completeness', () {
      // Two cases, and adding a third to `Verdict` stops this compiling.
      String describe(Verdict verdict) => switch (verdict) {
        Within(:final remaining) => 'ok, ${remaining.asText} left',
        Breach(:final over) => 'no, ${over.asText} over',
      };
      expect(describe(budgetOver([]).on(spent(100))), 'ok, £199.00 left');
      expect(describe(budgetOver([]).on(spent(30000))), 'no, £100.00 over');
    });
  });
  // #endregion verdict

  // #region stored
  group('a limit is stored, and a budget is not', () {
    test('a limit writes itself down with a kind, and reads back', () {
      expect(food.toJson(), {
        'kind': 'limit',
        'category': 'food',
        'pence': 20000,
      });
      expect(limitFromJson(food.toJson()), food);
    });

    test('and an expense is not a limit, whatever keys it shares', () {
      final expense = spent(100).toJson();
      expect(expense.containsKey('category'), isTrue);
      expect(expense.containsKey('pence'), isTrue);
      expect(
        limitFromJson(expense),
        isNull,
        reason: "the constant pattern 'kind': 'limit' is what keeps them apart",
      );
    });

    test('and a limit is not an expense', () {
      expect(expenseFromJson(food.toJson()), isNull);
    });

    test('a limit the domain refuses, which JSON was happy with', () {
      expect(
        () => Limit(Category('food'), Money.zero),
        throwsArgumentError,
        reason:
            'the refusal lives on the type; the reader below only asks '
            'first, so a hand-edited file never reaches the throw',
      );
      expect(limitFromJson({...food.toJson(), 'pence': 0}), isNull);
      expect(limitFromJson({...food.toJson(), 'pence': -1}), isNull);
      expect(limitFromJson({...food.toJson(), 'category': '  '}), isNull);
      expect(limitFromJson({...food.toJson(), 'kind': 'expense'}), isNull);
    });
  });
  // #endregion stored

  // #region acknowledged
  group('an acknowledged overspend is a different thing', () {
    test('and says so on the line it prints', () {
      final over = Expense(
        Money.fromPence(100),
        Category('food'),
        Day(2026, 9, 9),
        'lunch',
        acknowledged: true,
      );
      expect(over.asText, endsWith('(over budget)'));
      expect(spent(100).asText, isNot(contains('over budget')));
    });

    test('and survives the round trip', () {
      final over = Expense(
        Money.fromPence(100),
        Category('food'),
        Day(2026, 9, 9),
        'lunch',
        acknowledged: true,
      );
      expect(over.toJson()['acknowledged'], isTrue);
      expect(expenseFromJson(over.toJson())?.acknowledged, isTrue);
    });

    test('while an ordinary expense writes the four keys study 29 wrote', () {
      expect(spent(100).toJson().keys, ['day', 'pence', 'category', 'note']);
    });

    test('so every line study 29 and 30 wrote still reads', () {
      const old = {
        'day': '2026-09-09',
        'pence': 1250,
        'category': 'food',
        'note': 'coffee',
      };
      expect(expenseFromJson(old)?.acknowledged, isFalse);
      expect(expenseFromJson(old)?.note, 'coffee');
    });
  });
  // #endregion acknowledged
}
