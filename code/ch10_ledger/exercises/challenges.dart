// Study 10 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// All three want a loop. None of them wants a method you have not met — if you
// reach for something clever, write the loop instead and let study 12 take it
// away from you later.

/// 1. The balance after each entry, in order.
///    `runningBalance([100, -30, 5])` is `[100, 70, 75]`, and an empty ledger
///    has an empty history.
List<int> runningBalance(List<int> entries) {
  throw UnimplementedError('challenge 1');
}

/// 2. The length of the longest unbroken run of money coming in.
///    `longestRun([100, 200, -50, 300])` is `2`. A debit or a blank line ends
///    a run. A ledger with nothing coming in has a longest run of `0`.
int longestRun(List<int> entries) {
  throw UnimplementedError('challenge 2');
}

/// 3. The fewest coins that make up [pence], using 200, 100, 50, 20, 10, 5, 2
///    and 1. `coinsNeeded(260)` is `3` — a 200, a 50 and a 10. Take the
///    largest coin that still fits, as many times as it fits, then move down.
int coinsNeeded(int pence) {
  throw UnimplementedError('challenge 3');
}
