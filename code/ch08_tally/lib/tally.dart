// #region tally
/// Counts how often each word appears in [words].
///
/// `counts[word]` is an `int?` — a count or nothing — because the word may not
/// be in the map yet. `?? 0` reads as "that, or zero if it is nothing".
/// Study 9 is about that question mark.
Map<String, int> tally(List<String> words) {
  final counts = <String, int>{};
  for (final word in words) {
    counts[word] = (counts[word] ?? 0) + 1;
  }
  return counts;
}
// #endregion tally

// #region unique
/// Every distinct word in [words], in the order they first appeared.
Set<String> unique(List<String> words) => {...words};
// #endregion unique

// #region sets
/// The words in both [a] and [b].
Set<String> shared(Set<String> a, Set<String> b) => a.intersection(b);

/// The words in one of [a] and [b] but not in both.
Set<String> exclusive(Set<String> a, Set<String> b) =>
    a.union(b).difference(a.intersection(b));
// #endregion sets
