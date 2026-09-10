import 'package:ch30_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  // #region covers
  group('a period is the days of one calendar month', () {
    test('and knows both ends of itself', () {
      expect(Period(2026, 9).first, Day(2026, 9, 1));
      expect(Period(2026, 9).last, Day(2026, 9, 30));
    });

    test('including the ends nobody remembers', () {
      expect(Period(2026, 2).last, Day(2026, 2, 28));
      expect(Period(2024, 2).last, Day(2024, 2, 29));
      expect(Period(1900, 2).last, Day(1900, 2, 28));
      expect(Period(2000, 2).last, Day(2000, 2, 29));
    });

    test('a day is in it when it shares the year and the month', () {
      final september = Period(2026, 9);
      expect(september.contains(Day(2026, 9, 1)), isTrue);
      expect(september.contains(Day(2026, 9, 30)), isTrue);
      expect(september.contains(Day(2026, 8, 31)), isFalse);
      expect(september.contains(Day(2026, 10, 1)), isFalse);
      expect(september.contains(Day(2025, 9, 15)), isFalse);
    });

    test('and the month a day falls in is the period that contains it', () {
      for (final day in [Day(2026, 2, 1), Day(2026, 2, 28)]) {
        expect(Period.of(day).contains(day), isTrue);
        expect(Period.of(day), Period(2026, 2));
      }
    });
  });
  // #endregion covers

  // #region value
  group('and it is a value, by study 25 rules', () {
    test('two periods for the same month are the same period', () {
      expect(Period(2026, 9), Period(2026, 9));
      expect(Period(2026, 9).hashCode, Period(2026, 9).hashCode);
      expect(Period.of(Day(2026, 9, 9)), Period(2026, 9));
    });

    test('and a month that does not exist is not one', () {
      expect(() => Period(2026, 0), throwsArgumentError);
      expect(() => Period(2026, 13), throwsArgumentError);
    });
  });
  // #endregion value

  // #region parse
  group('reading a month off a command line', () {
    test('reads the shape it writes', () {
      expect(Period.parse('2026-09'), Period(2026, 9));
      expect(Period.parse(Period(2024, 2).asText), Period(2024, 2));
      expect(Period(2026, 9).asText, '2026-09');
    });

    test('and answers null for everything else', () {
      for (final text in [
        '',
        '2026-9',
        '2026/09',
        '2026-00',
        '2026-13',
        '2026-09-09',
        'September',
      ]) {
        expect(Period.parse(text), isNull, reason: 'Period.parse("$text")');
      }
    });

    test('including the negative year Day.parse taught us to expect', () {
      expect(Period.parse('-123-01'), isNull);
      expect(int.tryParse('-123'), -123, reason: 'why the check is positional');
    });
  });
  // #endregion parse
}
