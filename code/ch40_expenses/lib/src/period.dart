import 'day.dart';

// #region period
/// The stretch of days a report covers: one calendar month.
///
/// **Not a start and a length.** A `Duration` is a fixed number of
/// microseconds and has never heard of a calendar, so there is no `Duration`
/// that means *a month*: February 2026 is 28 days, March is 31, and February
/// 2024 is 29. A period is a year and a month, and the days it covers are
/// worked out from the calendar rather than counted off a clock.
///
/// Two integers, both of them things a person says out loud. Nothing in here
/// is an instant, so nothing in here has a time zone to get wrong.
class const Period._(final int year, final int month) {
  /// One calendar month, or an [ArgumentError] for a month number that is
  /// not one.
  factory Period(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'not a month');
    }
    return Period._(year, month);
  }

  /// The month a day falls in.
  factory Period.of(Day day) => Period._(day.year, day.month);

  /// A period from `YYYY-MM`, or `null` for anything that is not one.
  ///
  /// Total, and positional, for exactly [Day.parse]'s reasons: this reads what
  /// a person typed at a shell, so a wrong shape is an answer rather than a
  /// throw, and `-123-01` would otherwise parse as the year -123.
  static Period? parse(String text) {
    if (text.length != 7 || text[4] != '-') return null;
    for (var i = 0; i < 7; i++) {
      if (i == 4) continue;
      final unit = text.codeUnitAt(i);
      if (unit < 0x30 || unit > 0x39) return null;
    }
    final month = int.parse(text.substring(5, 7));
    if (month < 1 || month > 12) return null;
    return Period._(int.parse(text.substring(0, 4)), month);
  }

  /// The first day this period covers. Always the 1st, in every month there
  /// has ever been.
  Day get first => Day(year, month, 1);

  /// The last day this period covers, which is the only interesting one and
  /// the whole reason [Day.lastDayOf] is public.
  Day get last => Day(year, month, Day.lastDayOf(year, month));

  /// Whether a day falls in this month.
  ///
  /// Two integer comparisons, and deliberately no ordering. A calendar month
  /// *is* the days that share its year and its month, so asking whether a day
  /// sits between [first] and [last] would be a longer way to the same answer
  /// with two ends to get wrong.
  bool contains(Day day) => day.year == year && day.month == month;

  /// The period as `YYYY-MM`, the form [parse] reads back.
  String get asText => '$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Period && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => asText;
}
// #endregion period
