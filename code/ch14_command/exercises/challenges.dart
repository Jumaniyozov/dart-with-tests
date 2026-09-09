// Study 14 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Every one of them can be written as a pattern. If you find yourself
// counting list positions by hand or writing `if (x != null)`, there is a
// pattern that already does it.

/// 1. Reads `'3-7'` into `(3, 7)`. Anything that is not two whole numbers
///    with one dash between them is nothing: `'3'`, `'3-7-9'` and `'a-b'`
///    all read as `null`.
(int, int)? asRange(String line) {
  throw UnimplementedError('challenge 1');
}

/// 2. Turns a result into a verdict.
///    Not passed is `'failed'`, whatever the score. Passed with 90 or more is
///    `'distinction'`. Passed otherwise is `'passed'`.
///    Write it as one switch expression with no `default`.
String verdict((int score, bool passed) result) {
  throw UnimplementedError('challenge 2');
}

/// 3. `label(('rent', (12, 34)))` is `'rent £12.34'`. The pence are always
///    two digits: `label(('bus', (0, 5)))` is `'bus £0.05'`.
String label((String name, (int pounds, int pence)) entry) {
  throw UnimplementedError('challenge 3');
}
