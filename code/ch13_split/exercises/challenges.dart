// Study 13 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Every one of them hands back more than one value. None of them needs a
// class — that is study 15, and part of the point of this study is noticing
// how far you get without one.

/// 1. [seconds] as whole minutes and the seconds left over.
///    `asMinutes(125)` is `(2, 5)`, and `asMinutes(30)` is `(0, 30)`.
(int, int) asMinutes(int seconds) {
  throw UnimplementedError('challenge 1');
}

/// 2. The money in and the money out of a ledger, as two named fields, both
///    positive. `flows([100, -30, 50])` is `(inward: 150, outward: 30)`.
({int inward, int outward}) flows(List<int> entries) {
  throw UnimplementedError('challenge 2');
}

/// 3. The first duplicate in [entries] and where it was first seen:
///    `firstRepeat([5, 9, 5])` is `(5, 0)` — the value, then the index it
///    first appeared at. Nothing repeated is `null`.
(int value, int firstIndex)? firstRepeat(List<int> entries) {
  throw UnimplementedError('challenge 3');
}
