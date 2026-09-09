// #region range
/// The obvious bound: "T is something that can be compared to a T."
///
/// It compiles, and it is wrong in a way nothing warns you about.
class Range<T extends Comparable<T>> {
  final T low;
  final T high;

  new(this.low, this.high)
    : assert(low.compareTo(high) <= 0, 'low must not be above high');

  bool contains(T value) =>
      low.compareTo(value) <= 0 && high.compareTo(value) >= 0;
}
// #endregion range

// #region largest
T largestOf<T extends Comparable<T>>(List<T> values) =>
    values.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
// #endregion largest
