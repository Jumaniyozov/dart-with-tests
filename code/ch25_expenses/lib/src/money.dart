// #region money
/// An amount of money the tracker records. Never negative.
///
/// The constructor below is named `_`, so it belongs to this file and nothing
/// outside can call it. Every `Money` that exists anywhere else came through
/// [Money.fromPence] and was checked on the way.
class const Money._(final int pence) {
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

  /// Pounds and pence, written the way a person says them.
  String get asText =>
      '£${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
}
// #endregion money
