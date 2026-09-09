// #region split
/// [amount] in pence, as whole pounds and the pence left over.
///
/// Study 4 could only hand back one of these at a time.
(int, int) splitPence(int amount) => (amount ~/ 100, amount % 100);
// #endregion split

// #region named
/// The same split, with its fields named instead of counted.
({int pounds, int pence}) breakDown(int amount) =>
    (pounds: amount ~/ 100, pence: amount % 100);
// #endregion named

// #region format
/// `1234` reads `£12.34`.
String format(int amount) {
  final (pounds, pence) = splitPence(amount);
  return '£$pounds.${pence.toString().padLeft(2, '0')}';
}
// #endregion format

// #region range
/// The smallest and largest of [entries], together.
///
/// The names in the return type are for whoever reads this line. They do not
/// become getters — the fields are still `$1` and `$2`.
(int smallest, int largest) rangeOf(List<int> entries) => (
  entries.reduce((a, b) => a < b ? a : b),
  entries.reduce((a, b) => a > b ? a : b),
);
// #endregion range

// #region key
/// How many amounts share each pounds-and-pence split.
///
/// A record can be a `Map` key because equal records have equal hash codes.
/// A `List` cannot, which is what study 8 ran into.
Map<(int, int), int> tallySplits(List<int> amounts) {
  final counts = <(int, int), int>{};
  for (final amount in amounts) {
    final split = splitPence(amount);
    counts[split] = (counts[split] ?? 0) + 1;
  }
  return counts;
}
// #endregion key
