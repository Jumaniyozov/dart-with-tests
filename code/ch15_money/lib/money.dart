// #region money
/// An amount of money, held as a whole number of pence.
///
/// Negative is money out, the way the ledger in study 10 meant it.
class const Money(final int pence) {
  /// The whole pounds in this amount, ignoring its sign.
  int get pounds => pence.abs() ~/ 100;

  /// The pence left over after [pounds], ignoring the sign.
  int get pencePart => pence.abs() % 100;

  /// Whether this is money going out.
  bool get isDebit => pence < 0;

  /// This amount and [other] together.
  Money plus(Money other) => Money(pence + other.pence);

  /// [quantity] of this amount.
  Money times(int quantity) => Money(pence * quantity);

  /// `250` reads `£2.50`, and `-250` reads `-£2.50`.
  String format() =>
      '${isDebit ? '-' : ''}£$pounds.${pencePart.toString().padLeft(2, '0')}';
  // #endregion money

  // #region equality
  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;

  @override
  String toString() => 'Money(${format()})';
  // #endregion equality
}

// #region split
/// Pounds and a pence part, where the pence part really is part of a pound.
///
/// Study 13 returned these two numbers as a record and could promise nothing
/// about them. This can, which is why it is written out rather than declared
/// in the header: a primary constructor has nowhere to put the check.
class Split {
  final int pounds;
  final int pence;

  const new(this.pounds, this.pence)
    : assert(pounds >= 0, 'a split describes an amount, not a direction'),
      assert(pence >= 0 && pence < 100, 'pence must be a part of a pound');

  /// Breaks a whole number of pence into the two parts.
  ///
  /// Only for an amount of nothing or more. `-7` would split into `0` pounds
  /// and `93` pence — Dart's `%` is never negative — which is a different
  /// amount entirely, so the constructor refuses it rather than answering it.
  factory fromPence(int total) {
    assert(total >= 0, 'a split describes an amount, not a direction');
    return Split(total ~/ 100, total % 100);
  }

  /// The two parts back together.
  Money get amount => Money(pounds * 100 + pence);
}
// #endregion split
