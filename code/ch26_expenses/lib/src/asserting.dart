// #region asserting
/// Halves an even number, and asserts that it was given one.
///
/// Run `bin/asserting.dart` three ways and read 26.4. The answer is not the
/// same each time, and the one that never fires is the one you ship.
///
/// This file is a demonstration and is deliberately **not** exported by
/// `lib/expenses.dart`. Study 23 made the barrel a statement about what this
/// package supports, and nobody should build on `half`. `bin/asserting.dart`
/// reaches into `lib/src/` directly, which is allowed inside one package.
int half(int number) {
  assert(number.isEven, 'half wants an even number');
  return number ~/ 2;
}
// #endregion asserting
