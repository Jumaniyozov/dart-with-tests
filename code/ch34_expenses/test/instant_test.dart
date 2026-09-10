import 'package:ch34_expenses/expenses.dart';
import 'package:test/test.dart';

/// Everything in this file is true in every time zone on Earth.
///
/// That is not a boast, it is the entry fee. A test that passes in Tashkent and
/// fails in London would be measuring the machine it ran on, and a reader
/// cannot check a claim like that. Where a fact genuinely depends on where you
/// are standing — and one below does — the assertion is about *that dependence*
/// rather than about the answer.
void main() {
  // #region equality
  group('a DateTime is an instant, and its == says so', () {
    final local = DateTime(2026, 9, 9);
    final utc = local.toUtc();

    test('the two are the same moment', () {
      expect(local.microsecondsSinceEpoch, utc.microsecondsSinceEpoch);
      expect(local.isAtSameMomentAs(utc), isTrue);
    });

    test('and are not equal', () {
      expect(local == utc, isFalse);
      expect(local.isUtc, isFalse);
      expect(utc.isUtc, isTrue);
    });

    test('while having the same hashCode', () {
      expect(local.hashCode, utc.hashCode);
    });

    test('which is the pair study 25 said to watch for', () {
      // 25.4: equal hash codes are not evidence of equality. Here is the one
      // in dart:core that proves it, and it is not a bug — `==` answers "the
      // same reading of the same clock", and these are two readings.
      expect(local.hashCode == utc.hashCode, isTrue);
      expect(local == utc, isFalse);
    });
  });
  // #endregion equality

  // #region offset
  group('and writes itself down without saying which one it is', () {
    test('a local DateTime carries no offset at all', () {
      expect(DateTime(2026, 9, 9).toIso8601String(), '2026-09-09T00:00:00.000');
    });

    test('so the same string means a different instant in each place', () {
      // The one fact here that depends on where this runs. It is asserted as a
      // dependence: the local form is missing the thing the UTC form carries,
      // which is true everywhere, rather than "the date differs", which is only
      // true east of Greenwich.
      final local = DateTime(2026, 9, 9);
      expect(local.toIso8601String(), isNot(endsWith('Z')));
      expect(local.toUtc().toIso8601String(), endsWith('Z'));
      expect(local.toUtc().toIso8601String(), isNot(local.toIso8601String()));
    });

    test('and parsing one that does carry an offset throws it away', () {
      // Written on the 10th, by somebody five hours ahead of Greenwich.
      final parsed = DateTime.parse('2026-09-10T04:30:00+05:00');
      expect(parsed.isUtc, isTrue);
      expect(
        parsed.day,
        9,
        reason: 'the calendar day it was written with is simply gone',
      );
      expect(parsed.toIso8601String(), '2026-09-09T23:30:00.000Z');
    });

    test('so two DateTimes written on different days can be equal', () {
      expect(
        DateTime.parse('2026-09-10T04:30:00+05:00'),
        DateTime.parse('2026-09-09T23:30:00Z'),
      );
    });
  });
  // #endregion offset

  // #region overflow
  group('and refuses nothing', () {
    test('the 31st of February is the 3rd of March, silently', () {
      expect(DateTime(2026, 2, 31), DateTime(2026, 3, 3));
    });

    test('and the 13th month is next January', () {
      expect(DateTime(2026, 13, 1), DateTime(2027, 1, 1));
    });

    test('and parse does it too, which is the one that reaches a file', () {
      // Study 29 stores `2026-09-09` and reads it back with `Day.parse`. Had it
      // stored a DateTime instead, this is what an edited file would do: no
      // throw, no null, just a different day than the one written down.
      expect(DateTime.parse('2026-02-31'), DateTime(2026, 3, 3));
      expect(DateTime.parse('2026-09-09T25:00'), DateTime(2026, 9, 10, 1));
      expect(Day.parse('2026-02-31'), isNull, reason: 'the type that refuses');
    });

    test('while Day says no, which is the only difference that matters', () {
      expect(() => Day(2026, 2, 31), throwsArgumentError);
      expect(() => Day(2026, 13, 1), throwsArgumentError);
    });

    test('and the same overflow is how you ask a month its length', () {
      // Day zero of a month is the last day of the one before. It is the
      // standard trick, it is correct, and it is the same mechanism as the bug
      // three tests up — which is why `Day.lastDayOf` writes the table out
      // instead.
      expect(DateTime(2026, 3, 0), DateTime(2026, 2, 28));
      expect(DateTime(2024, 3, 0), DateTime(2024, 2, 29));
      expect(Day.lastDayOf(2026, 2), 28);
      expect(Day.lastDayOf(2024, 2), 29);
      expect(Day.lastDayOf(1900, 2), 28, reason: 'not every fourth year');
    });
  });
  // #endregion overflow

  // #region duration
  group('a Duration is a count of microseconds, not a stretch of calendar', () {
    test('a day is twenty-four hours to a Duration, always', () {
      expect(const Duration(days: 1), const Duration(hours: 24));
      expect(const Duration(days: 1).inHours, 24);
    });

    test('and there is no Duration that means a month', () {
      // Three months, three lengths, and no arithmetic that turns one into
      // another. This is why `Period` holds a year and a month rather than a
      // start and a length.
      expect(Period(2026, 2).last.day, 28);
      expect(Period(2024, 2).last.day, 29);
      expect(Period(2026, 3).last.day, 31);
      expect(Period(2026, 4).last.day, 30);
    });

    test('difference between two instants is hours, whatever you asked', () {
      final gap = DateTime.utc(
        2026,
        9,
        10,
      ).difference(DateTime.utc(2026, 9, 9));
      expect(gap, const Duration(hours: 24));
      expect(gap.inDays, 1);
      expect(
        const Duration(hours: 25).inDays,
        1,
        reason: 'inDays truncates; it does not consult a calendar',
      );
    });
  });
  // #endregion duration
}
