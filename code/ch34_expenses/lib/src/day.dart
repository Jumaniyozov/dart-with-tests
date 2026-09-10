// #region day
/// A calendar day. The same day everywhere on Earth.
///
/// Not a `DateTime`. A `DateTime` is an instant — a point on a timeline, which
/// belongs to a place as much as to a date. An expense happened on a day, and
/// the 9th of September is the 9th of September in Tashkent and in London.
///
/// `test/instant_test.dart` measures the four separate ways a `DateTime` gets
/// this wrong. This type exists because of them.
class const Day._(final int year, final int month, final int day)
    implements Comparable<Day> {
  /// A real calendar day, or an [ArgumentError] for one that never was.
  ///
  /// The 31st of February is refused rather than rolled forward, which is
  /// the whole reason this type exists rather than a `DateTime`.
  factory Day(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'not a month');
    }
    final last = lastDayOf(year, month);
    if (day < 1 || day > last) {
      throw ArgumentError.value(day, 'day', 'that month has $last days');
    }
    return Day._(year, month, day);
  }

  /// How long a month is, which depends on which month and sometimes which
  /// year. Checking `day <= 31` would let this type hold the 31st of
  /// February — a date that has never existed, in a type whose whole reason
  /// to exist is being a real calendar day.
  ///
  /// Public from this study on, and the underscore was the only thing that had
  /// to change. `Period` needs the length of a month and lives in another
  /// file, and study 23's rule is that a file is the boundary — so a helper
  /// two types share cannot stay private to one of them.
  ///
  /// The tempting alternative is `DateTime(year, month + 1, 0)`, which really
  /// does answer the 28th of February for March 2026. It works by the same
  /// silent overflow that turns the 31st of February into the 3rd of March,
  /// and it hands back an instant when the question was about a calendar.
  static int lastDayOf(int year, int month) => switch (month) {
    2 => _isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  /// Every fourth year, except every hundredth, except every four-hundredth.
  /// 2000 was a leap year and 1900 was not.
  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// A day from `YYYY-MM-DD`, or `null` for anything that is not one.
  ///
  /// Total on purpose. This is called on text out of a file, which a person may
  /// have edited, so a wrong shape is the world being awkward rather than a bug
  /// — study 26's rule, and it decides the return type.
  ///
  /// The character check is not decoration, and it has to be **positional**.
  /// `int.parse` accepts a sign wherever it is handed one, and `-123-01-01` is
  /// ten characters with a dash in each of the two places this shape wants one,
  /// so it would parse as the year -123. Asking only whether every character is
  /// a digit *or* a dash is not enough — that was the first version of this
  /// method and the test above caught it. Every position except 4 and 7 must be
  /// a digit and nothing else.
  static Day? parse(String text) {
    if (text.length != 10 || text[4] != '-' || text[7] != '-') return null;
    for (var i = 0; i < 10; i++) {
      if (i == 4 || i == 7) continue;
      final unit = text.codeUnitAt(i);
      if (unit < 0x30 || unit > 0x39) return null;
    }
    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(5, 7));
    final day = int.parse(text.substring(8, 10));
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > lastDayOf(year, month)) return null;
    return Day._(year, month, day);
  }

  /// The day an instant fell on, where the program is running.
  ///
  /// This is the edge. An instant comes in, a day comes out, and nothing
  /// downstream has to think about time zones again.
  factory Day.on(DateTime instant) =>
      Day(instant.year, instant.month, instant.day);

  /// The day as `YYYY-MM-DD`, which is what a file holds and a person reads.
  String get asText =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Day &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Earlier days first.
  ///
  /// Year, then month, then day, and each one only consulted when the one
  /// before it ties. Comparing `asText` would give the same answer for these
  /// three fields — that is what zero-padding an ISO date buys — but it would
  /// be an accident of the format rather than a statement about calendars.
  @override
  int compareTo(Day other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  String toString() => asText;
}
// #endregion day
