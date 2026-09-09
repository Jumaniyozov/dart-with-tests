// #region day
/// A calendar day. The same day everywhere on Earth.
///
/// Not a `DateTime`. A `DateTime` is an instant — a point on a timeline, which
/// belongs to a place as much as to a date. An expense happened on a day, and
/// the 9th of September is the 9th of September in Tashkent and in London.
///
/// Study 30 measures the four separate ways a `DateTime` gets this wrong. This
/// type exists because of them.
class const Day._(final int year, final int month, final int day) {
  factory Day(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'not a month');
    }
    final last = _lastDayOf(year, month);
    if (day < 1 || day > last) {
      throw ArgumentError.value(day, 'day', 'that month has $last days');
    }
    return Day._(year, month, day);
  }

  /// How long a month is, which depends on which month and sometimes which
  /// year. Checking `day <= 31` would let this type hold the 31st of
  /// February — a date that has never existed, in a type whose whole reason
  /// to exist is being a real calendar day.
  static int _lastDayOf(int year, int month) => switch (month) {
    2 => _isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  /// Every fourth year, except every hundredth, except every four-hundredth.
  /// 2000 was a leap year and 1900 was not.
  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// The day an instant fell on, where the program is running.
  ///
  /// This is the edge. An instant comes in, a day comes out, and nothing
  /// downstream has to think about time zones again.
  factory Day.on(DateTime instant) =>
      Day(instant.year, instant.month, instant.day);

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

  @override
  String toString() => asText;
}
// #endregion day
