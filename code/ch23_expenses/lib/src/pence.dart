// #region pence
/// Study 19's `Pence`, with the door shut as far as it will shut.
///
/// The constructor is private, exactly like [Money]'s. 23.4 measures whether
/// that is enough.
extension type const Pence._(int value) {
  factory Pence.fromValue(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'money is never negative');
    }
    return Pence._(value);
  }
}
// #endregion pence
