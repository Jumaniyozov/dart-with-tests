import 'package:ch30_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — the month after this one', () {
    test('is the next month, most of the time', () {
      expect(nextMonth(Period(2026, 9)), Period(2026, 10));
      expect(nextMonth(Period(2026, 1)), Period(2026, 2));
    });

    test('and January of the next year in December', () {
      expect(nextMonth(Period(2026, 12)), Period(2027, 1));
      expect(nextMonth(Period(1999, 12)), Period(2000, 1));
    });

    test('and twelve of them come back where they started', () {
      var period = Period(2026, 3);
      for (var i = 0; i < 12; i++) {
        period = nextMonth(period);
      }
      expect(period, Period(2027, 3));
    });
  });

  group('challenge 2 — how long a month is', () {
    test('the ones that never change', () {
      expect(daysIn(Period(2026, 1)), 31);
      expect(daysIn(Period(2026, 4)), 30);
      expect(daysIn(Period(2026, 9)), 30);
      expect(daysIn(Period(2026, 12)), 31);
    });

    test('and February, which does', () {
      expect(daysIn(Period(2026, 2)), 28);
      expect(daysIn(Period(2024, 2)), 29);
    });

    test('including the century rule', () {
      expect(daysIn(Period(1900, 2)), 28);
      expect(daysIn(Period(2000, 2)), 29);
    });

    test('and a year adds up to what a year adds up to', () {
      var total = 0;
      for (var month = 1; month <= 12; month++) {
        total += daysIn(Period(2026, month));
      }
      expect(total, 365);
      expect(
        [for (var month = 1; month <= 12; month++) daysIn(Period(2024, month))]
            .reduce((a, b) => a + b),
        366,
      );
    });
  });

  group('challenge 3 — the last working day', () {
    test('is the last day, when the last day is a weekday', () {
      expect(lastWorkingDayOf(Period(2026, 9)), Day(2026, 9, 30));
      expect(lastWorkingDayOf(Period(2024, 2)), Day(2024, 2, 29));
      expect(lastWorkingDayOf(Period(2026, 8)), Day(2026, 8, 31));
    });

    test('and steps back over a Saturday', () {
      expect(lastWorkingDayOf(Period(2026, 2)), Day(2026, 2, 27));
    });

    test('and over a whole weekend', () {
      expect(lastWorkingDayOf(Period(2026, 5)), Day(2026, 5, 29));
      expect(lastWorkingDayOf(Period(2027, 1)), Day(2027, 1, 29));
    });

    test('and always lands inside the month it was asked about', () {
      for (var month = 1; month <= 12; month++) {
        final period = Period(2026, month);
        expect(period.contains(lastWorkingDayOf(period)), isTrue);
      }
    });
  });
}
