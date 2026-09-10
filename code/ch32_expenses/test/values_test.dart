import 'package:ch32_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  group('a category is a value', () {
    test('and is normalised once, on the way in', () {
      expect(Category('  Food  ').name, 'food');
      expect(Category('FOOD'), Category('food'));
    });

    test('so two spellings are one key in a map', () {
      final counts = <Category, int>{};
      counts[Category('Food')] = 1;
      counts[Category(' food ')] = 2;
      expect(counts, hasLength(1), reason: 'the same category, written twice');
      expect(counts[Category('FOOD')], 2);
    });

    test('and equal categories agree about their hash code', () {
      expect(Category('Food').hashCode, Category('food').hashCode);
    });

    test('a category with no name in it is refused', () {
      expect(() => Category('   '), throwsArgumentError);
    });
  });

  group('money is a value too', () {
    test('two amounts of the same pence are the same amount', () {
      expect(Money.fromPence(250), Money.fromPence(250));
      expect(Money.fromPence(250) == Money.fromPence(251), isFalse);
    });

    test('so it survives a set and a map key', () {
      expect({Money.fromPence(250), Money.fromPence(250)}, hasLength(1));
      expect(Money.fromPence(250).hashCode, Money.fromPence(250).hashCode);
    });
  });

  group('an expense is an entity', () {
    final day = Day(2026, 9, 9);
    Expense coffee() =>
        Expense(Money.fromPence(320), Category('food'), day, 'coffee');

    test('two of the same thing are two things, not one', () {
      expect(coffee() == coffee(), isFalse);
    });

    test('and it is equal to itself', () {
      final one = coffee();
      expect(one, one);
    });

    test('so a set of them counts both', () {
      expect({coffee(), coffee()}, hasLength(2));
    });
  });

  group('a day is a value and not an instant', () {
    test('two days with the same parts are the same day', () {
      expect(Day(2026, 9, 9), Day(2026, 9, 9));
      expect(Day(2026, 9, 9).hashCode, Day(2026, 9, 9).hashCode);
    });

    test('and it reads the way a date reads', () {
      expect(Day(2026, 9, 9).asText, '2026-09-09');
      expect(Day(2026, 12, 25).asText, '2026-12-25');
    });

    test('a month that is not a month is refused', () {
      expect(() => Day(2026, 13, 1), throwsArgumentError);
      expect(() => Day(2026, 0, 1), throwsArgumentError);
    });

    test('and a day that month has never had', () {
      // The reason this type exists is that it is a real calendar day.
      // Checking `day <= 31` would let it hold the 31st of February.
      expect(() => Day(2026, 2, 31), throwsArgumentError);
      expect(() => Day(2026, 4, 31), throwsArgumentError);
      expect(() => Day(2026, 1, 0), throwsArgumentError);
    });

    test('February knows which years are long', () {
      expect(Day(2024, 2, 29).asText, '2024-02-29');
      expect(() => Day(2025, 2, 29), throwsArgumentError);
      expect(
        Day(2000, 2, 29).asText,
        '2000-02-29',
        reason: '400 is a leap year',
      );
      expect(() => Day(1900, 2, 29), throwsArgumentError, reason: '100 is not');
    });
  });

  group('the store hands out a list nobody can change', () {
    test('adding to what it returns throws', () async {
      final Store store = InMemoryStore();
      await store.record(
        Expense(
          Money.fromPence(100),
          Category('food'),
          Day(2026, 9, 9),
          'apple',
        ),
      );
      final handed = await store.all;
      expect(() => handed.add(handed.first), throwsUnsupportedError);
      expect(handed, hasLength(1));
    });
  });
}
