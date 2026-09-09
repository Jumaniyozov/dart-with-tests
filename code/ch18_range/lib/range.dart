// #region range
/// A pair of bounds guaranteed to be the right way round.
///
/// Study 13 returned `(smallest, largest)` as a record and could promise
/// nothing about which was which. This can, for any type that knows how to
/// compare itself.
///
/// The bound is `Comparable<Object>`, not the `Comparable<T>` you would write
/// first. Study 18 measures why.
class Range<T extends Comparable<Object>> {
  final T low;
  final T high;

  new(this.low, this.high)
    : assert(low.compareTo(high) <= 0, 'low must not be above high');

  bool contains(T value) =>
      low.compareTo(value) <= 0 && high.compareTo(value) >= 0;

  bool overlaps(Range<T> other) => contains(other.low) || other.contains(low);
}
// #endregion range

// #region tally
/// How often each value appears.
///
/// Study 8 wrote exactly this for `String` and nothing else. One letter is the
/// difference between a function for strings and a function for anything.
Map<T, int> tallyOf<T>(List<T> values) {
  final counts = <T, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}
// #endregion tally

// #region largest
/// The largest of [values], for anything that can be compared.
T largestOf<T extends Comparable<Object>>(List<T> values) =>
    values.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
// #endregion largest
