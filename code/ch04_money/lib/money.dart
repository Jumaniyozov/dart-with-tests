// #region constants
/// Money is counted in whole pence. Never in `double`.
const penceInPound = 100;

/// The largest order this shop will take, in pence: one million pounds.
const maxOrderPence = 100_000_000;
// #endregion constants

/// The cost of [quantity] items at [pence] each, in pence.
int total(int pence, int quantity) => pence * quantity;

// #region format
/// Writes [pence] the way a person reads it: `1234` becomes `£12.34`.
///
/// Expects an amount of zero or more. Negative amounts need a sign in front
/// of the pounds, which is challenge 2.
String format(int pence) {
  final pounds = pence ~/ penceInPound;
  final remainder = pence % penceInPound;
  return '£$pounds.${remainder.toString().padLeft(2, '0')}';
}
// #endregion format
