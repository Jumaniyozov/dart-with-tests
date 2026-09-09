// #region asserting
/// Halves an even number, and asserts that it was given one.
///
/// Run `bin/asserting.dart` four ways and read 26.4. The answer is not the
/// same each time, and the one that never fires is the one you ship.
int half(int number) {
  assert(number.isEven, 'half wants an even number');
  return number ~/ 2;
}
// #endregion asserting
