// #region money
/// A first Money: a name, a field and a method. Nothing else.
class const Money(final int pence) {
  int get pounds => pence.abs() ~/ 100;
}
// #endregion money
