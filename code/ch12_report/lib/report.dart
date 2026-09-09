// #region total
/// The balance. Study 10 wrote this as a loop with a running variable.
int total(List<int> entries) => entries.fold(0, (sum, entry) => sum + entry);
// #endregion total

// #region credits
/// The money coming in. Study 10 wrote this as a loop with a `continue`.
int creditsIn(List<int> entries) =>
    entries.where((entry) => entry > 0).fold(0, (sum, entry) => sum + entry);
// #endregion credits

// #region largest
/// The largest single entry.
///
/// `reduce` has no starting value, so it combines the elements with each other
/// and has nothing at all to hand back for an empty list.
int largest(List<int> entries) => entries.reduce((a, b) => a > b ? a : b);
// #endregion largest

// #region lines
/// How one entry is written on the report.
String describe(int pence) => pence > 0 ? '+${pence}p' : '${pence}p';

/// Every entry, written out. Note the return type: `map` does not make a list.
Iterable<String> lines(List<int> entries) => entries.map(describe);
// #endregion lines

// #region shared
/// The first amount in [mine] that also appears in [theirs], or `-1`.
///
/// Study 10 needed two nested loops and a label for this.
int firstShared(List<int> mine, List<int> theirs) =>
    mine.firstWhere(theirs.contains, orElse: () => -1);
// #endregion shared

// #region flatten
/// A week of days, run together into one list of entries.
Iterable<int> everyEntry(List<List<int>> days) => days.expand((day) => day);
// #endregion flatten

// #region page
/// One page of the report: [take] entries, starting after the first [skip].
Iterable<int> page(List<int> entries, {int skip = 0, int take = 3}) =>
    entries.skip(skip).take(take);
// #endregion page

// #region asking
/// Whether any money went out at all.
bool hasDebit(List<int> entries) => entries.any((entry) => entry < 0);

/// Whether every line has something on it.
bool allUsed(List<int> entries) => entries.every((entry) => entry != 0);
// #endregion asking
