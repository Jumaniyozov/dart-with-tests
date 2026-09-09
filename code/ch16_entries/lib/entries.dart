// #region entry
/// One line in a ledger, in whole pence. Money out is negative.
///
/// `sealed` says two things: this class has no instances of its own, and the
/// only types that can extend it are the ones in this file.
sealed class Entry {
  final int pence;

  const new(this.pence);

  bool get isDebit => pence < 0;
}
// #endregion entry

// #region family
class const Payment(super.pence, final String to) extends Entry {}

class const Refund(super.pence, final String from) extends Entry {}

class const Interest(super.pence, final int days) extends Entry {}
// #endregion family

// #region describe
/// What each entry says on the statement.
String describe(Entry entry) => switch (entry) {
  Payment(:final to) => 'paid $to',
  Refund(:final from) => 'refund from $from',
  Interest(:final days) => 'interest over $days days',
};
// #endregion describe

// #region total
/// The balance of a whole statement.
int balanceOf(List<Entry> entries) =>
    entries.fold(0, (sum, entry) => sum + entry.pence);

/// Only the money that went out.
List<Entry> debitsIn(List<Entry> entries) =>
    entries.where((entry) => entry.isDebit).toList();
// #endregion total

// #region rate
/// What each kind of entry costs to process, in pence.
///
/// A guard narrows inside a case the way study 14 showed, and the switch is
/// still exhaustive because every unguarded shape is covered.
int handlingFee(Entry entry) => switch (entry) {
  Payment(:final to) when to == 'self' => 0,
  Payment() => 25,
  Refund() => 0,
  Interest(:final days) when days > 90 => 100,
  Interest() => 50,
};
// #endregion rate

// #region band
/// How a statement line is grouped on the printed page.
///
/// Study 6 promised that an enum could carry fields and methods of its own
/// once classes existed. This is that promise: the constructor sits in the
/// header exactly as it does on a class, and the members come after the
/// semicolon that ends the list of values.
enum Band(final String heading, final int order) {
  incoming('Money in', 1),
  outgoing('Money out', 2);

  /// The band an entry is printed under.
  static Band of(Entry entry) => entry.isDebit ? .outgoing : .incoming;

  bool get isFirst => order == 1;

  @override
  String toString() => heading;
}
// #endregion band
