import 'package:ch35_expenses/expenses.dart';
import 'package:test/test.dart';

// #region fixtures
final day = Day(2026, 9, 9);

Expense spent(int pence, String category, {Day? on, String note = 'x'}) =>
    Expense(Money.fromPence(pence), Category(category), on ?? day, note);
// #endregion fixtures

void main() {
  // #region grouping
  group('a report groups by category', () {
    test('adding up everything that shares one', () {
      final report = Report.of([
        spent(100, 'food'),
        spent(250, 'food'),
        spent(300, 'transport'),
      ]);
      expect(report.lines, [
        CategoryTotal(Category('food'), Money.fromPence(350)),
        CategoryTotal(Category('transport'), Money.fromPence(300)),
      ]);
    });

    test('and it is Category.== doing the grouping, not the spelling', () {
      // Study 25 normalised on the way in, so all four of these are one
      // category. Nothing in this file mentions that, which is the point.
      final report = Report.of([
        spent(100, 'Food'),
        spent(100, 'food'),
        spent(100, ' FOOD '),
        spent(100, 'fOoD'),
      ]);
      expect(report.lines.single.spent, Money.fromPence(400));
    });

    test('an empty report is empty rather than absent', () {
      final report = Report.of([]);
      expect(report.isEmpty, isTrue);
      expect(report.lines, isEmpty);
      expect(report.total, Money.zero);
    });
  });
  // #endregion grouping

  // #region ordering
  group('and puts the dearest first', () {
    test('whatever order the expenses arrived in', () {
      final report = Report.of([
        spent(100, 'food'),
        spent(900, 'rent'),
        spent(300, 'transport'),
      ]);
      expect(
        [for (final line in report.lines) line.category.name],
        ['rent', 'transport', 'food'],
      );
    });

    test('breaking ties by name, so the answer never depends on luck', () {
      final report = Report.of([
        spent(500, 'transport'),
        spent(500, 'food'),
        spent(500, 'rent'),
      ]);
      expect(
        [for (final line in report.lines) line.category.name],
        ['food', 'rent', 'transport'],
      );
    });

    test('while the expenses themselves come back in day order', () {
      final report = Report.of([
        spent(100, 'food', on: Day(2026, 9, 30), note: 'last'),
        spent(100, 'food', on: Day(2026, 9, 1), note: 'first'),
        spent(100, 'food', on: Day(2026, 9, 9), note: 'middle'),
      ]);
      expect(
        [for (final expense in report.expenses) expense.note],
        ['first', 'middle', 'last'],
      );
    });

    test('which is Day.compareTo, and it is not string comparison', () {
      expect(Day(2026, 9, 1).compareTo(Day(2026, 10, 1)), isNegative);
      expect(Day(2026, 12, 31).compareTo(Day(2027, 1, 1)), isNegative);
      expect(Day(2026, 9, 9).compareTo(Day(2026, 9, 9)), isZero);
    });
  });
  // #endregion ordering

  // #region unstable
  group('why the tie-break is not tidiness', () {
    /// `List.sort` is not a stable sort, and it does not fail gradually. It
    /// keeps the order of equal elements exactly until it does not.
    List<String> sortedWithTiesOnly(int count) {
      final names = [for (var i = 0; i < count; i++) 'c${i + 100}'];
      return [...names]..sort((a, b) => 0);
    }

    test('33 equal elements keep the order they came in', () {
      final names = [for (var i = 0; i < 33; i++) 'c${i + 100}'];
      expect(sortedWithTiesOnly(33), names);
    });

    test('and 34 do not', () {
      final names = [for (var i = 0; i < 34; i++) 'c${i + 100}'];
      expect(
        sortedWithTiesOnly(34),
        isNot(names),
        reason:
            'measured on Dart 3.13.2: the implementation changes strategy, '
            'and every test anyone writes by hand is on the safe side of it',
      );
    });

    test('so CategoryTotal never returns 0 for two different categories', () {
      final food = CategoryTotal(Category('food'), Money.fromPence(500));
      final rent = CategoryTotal(Category('rent'), Money.fromPence(500));
      expect(food.compareTo(rent), isNot(0));
      expect(food.spent.compareTo(rent.spent), isZero, reason: 'the tie');
    });

    test(
      'and returning 0 is a claim about equality it must be able to keep',
      () {
        final same = CategoryTotal(Category('food'), Money.fromPence(500));
        final also = CategoryTotal(Category('food'), Money.fromPence(500));
        expect(same.compareTo(also), isZero);
        expect(same, also, reason: 'compareTo says 0, so == had better agree');
      },
    );
  });
  // #endregion unstable

  // #region money
  group('adding money up', () {
    test('two amounts make a third', () {
      expect(
        Money.fromPence(1250) + Money.fromPence(320),
        Money.fromPence(1570),
      );
    });

    test('zero is the identity, which is what fold starts from', () {
      expect(Money.zero + Money.fromPence(100), Money.fromPence(100));
      expect(Money.fromPence(100) + Money.zero, Money.fromPence(100));
      expect(Money.zero.pence, 0);
    });

    test('and the total is the lines added up', () {
      final report = Report.of([
        spent(1250, 'food'),
        spent(320, 'transport'),
        spent(100, 'food'),
      ]);
      expect(report.total, Money.fromPence(1670));
      expect(
        report.lines.fold(Money.zero, (sum, line) => sum + line.spent),
        report.total,
      );
    });

    test('money sorts by what it is worth', () {
      final amounts = [
        Money.fromPence(300),
        Money.fromPence(100),
        Money.fromPence(250),
      ]..sort();
      expect([for (final amount in amounts) amount.pence], [100, 250, 300]);
    });
  });
  // #endregion money
}
