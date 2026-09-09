// #region crowded
/// The same class as [Money], in a file that is not alone.
///
/// Nothing here is different. The check is the same check, the constructor is
/// as private as the other one. What changed is the company it keeps.
class const Amount._(final int pence) {
  factory Amount.fromPence(int pence) {
    if (pence < 0) {
      throw ArgumentError.value(pence, 'pence', 'money is never negative');
    }
    return Amount._(pence);
  }
}

/// Written by someone who needed an [Amount] and did not want to be told no.
///
/// This compiles. `dart analyze` says nothing about it. Privacy is a boundary
/// around the *file*, and this class is inside it.
class Backdoor {
  static Amount unchecked(int pence) => Amount._(pence);
}
// #endregion crowded
