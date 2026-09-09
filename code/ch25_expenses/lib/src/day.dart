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
    if (day < 1 || day > 31) {
      throw ArgumentError.value(day, 'day', 'not a day of any month');
    }
    return Day._(year, month, day);
  }

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
