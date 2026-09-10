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
  /// There is no `operator -` here. Subtraction can land below zero, which
  /// this type forbids, so it is a **partial** operation and needs somewhere
  /// for the failure to go. Study 32 gives it one: a budget, where a
  /// subtraction that will not go is exactly what an overspend is.
  Money operator +(Money other) => Money._(pence + other.pence);

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
