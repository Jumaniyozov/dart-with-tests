// #region money
/// An amount of money the tracker records. Never negative.
///
/// The constructor below is named `_`, so it belongs to this file and nothing
/// outside can call it. Every `Money` that exists anywhere else came through
/// [Money.fromPence] and was checked on the way.
class const Money._(final int pence) implements Comparable<Money> {
  /// Nothing spent. The identity for [operator +], which is what makes
  /// `fold` the natural way to add a list of these up.
  static const zero = Money._(0);

  /// The only door in from another library.
  ///
  /// The header above declares the class and its constructor at once and has
  /// no body to check in — study 15's rule. A factory has one, so the check
  /// goes here.
  factory Money.fromPence(int pence) {
    if (pence < 0) {
      throw ArgumentError.value(pence, 'pence', 'money is never negative');
    }
    return Money._(pence);
  }

  /// Two amounts of the same pence are the same amount. 25.3 asks one question
  /// of every new type — identical contents, one thing or two? — and money is
  /// the plainest *one thing* in the program.
  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;

  /// Two amounts, added.
  ///
  /// Total, and it goes through [Money._] rather than [Money.fromPence]
  /// because there is nothing left to check: both sides are already
  /// non-negative, so their sum is too. The invariant survives the operator
  /// without the operator having to defend it.
  ///
  /// `+` is **total**: every pair of amounts has a sum, and it goes through
  /// [Money._] rather than [Money.fromPence] because there is nothing left to
  /// check. Both sides are already non-negative, so the sum is too.
  Money operator +(Money other) => Money._(pence + other.pence);

  /// Two amounts, subtracted — or `null` when the answer would be money this
  /// type cannot hold.
  ///
  /// **A partial operation, and the signature says so.** `a + b` is an amount.
  /// `a - b` is an amount *or nothing*, because `Money` is never negative and
  /// £3 take away £5 is not £2 and is not zero either. There are three things
  /// to do about that and only one of them is honest: throw, which hides the
  /// failure from every caller's type; clamp to zero, which quietly reports the
  /// wrong number; or say it in the return type and make the caller decide.
  ///
  /// Study 31 wrote this operator's absence into its Wrapping up and left it
  /// out, because a report never subtracts and a `null` with nothing to mean
  /// is a worse answer than no operator at all. A budget gives it something to
  /// mean: `null` is an overspend.
  Money? operator -(Money other) =>
      pence >= other.pence ? Money._(pence - other.pence) : null;

  /// Cheaper first, dearer last.
  ///
  /// Implementing [Comparable] is a promise that this is a **total** order:
  /// every two amounts compare, and the answer never depends on which order
  /// you asked. `int.compareTo` already is one, so this is a delegation and
  /// not a decision.
  @override
  int compareTo(Money other) => pence.compareTo(other.pence);

  /// Pounds and pence, written the way a person says them.
  String get asText =>
      '£${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
}
// #endregion money
