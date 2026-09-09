// Study 20 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// One function is given, because all three challenges need it.

/// Given. The whole number [typed] describes.
///
/// Throws a [FormatException] when it does not describe one.
int wholeFrom(String typed) =>
    int.tryParse(typed) ?? (throw FormatException('not a number', typed));

/// An entry on a list was not a number.
class const BadEntry(final int at) implements Exception {
  @override
  String toString() => 'BadEntry: entry $at is not a number';
}

/// 1. Every entry added up, or a [BadEntry] naming the first one that is not
///    a number. `sumOf(['1', '2'])` is `3`. `sumOf(['1', 'x'])` throws a
///    `BadEntry` whose [BadEntry.at] is `1` — the position, counting from 0.
int sumOf(List<String> typed) {
  throw UnimplementedError('challenge 1');
}

/// 2. Who is wrong — the world, or the caller?
///
///    `priceOf('12', 3)` is `36`.
///
///    Text that is not a number is the world's fault, and [wholeFrom] already
///    throws the right thing for it. A [quantity] below 1 is the calling
///    code's fault, and 20.2 says what that means you throw instead. The
///    tests check that you agree with 20.2, not just that you threw
///    something.
int priceOf(String typed, int quantity) {
  throw UnimplementedError('challenge 2');
}

/// 3. Reads [typed] and leaves a record either way.
///
///    On success the log is `['trying', 'read', 'done']` and the number comes
///    back. On failure it is `['trying', 'refused', 'done']`, and the
///    exception still reaches the caller — carrying the trace it started
///    with, which is a question about *how* you send it on.
int readInto(String typed, List<String> log) {
  throw UnimplementedError('challenge 3');
}
