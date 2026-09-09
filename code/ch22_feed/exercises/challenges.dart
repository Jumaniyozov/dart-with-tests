// Study 22 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// One function is given, because all three challenges need something to
// listen to.

/// Given. A feed that records every value it sends in [log].
Stream<int> feedOf(List<int> values, List<String> log) async* {
  for (final value in values) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    log.add('sending $value');
    yield value;
  }
  log.add('feed done');
}

/// 1. The first value, the third, the fifth, and so on.
///
///    `everyOther` on a feed of 1, 2, 3, 4, 5 sends 1, 3, 5. An empty feed
///    sends nothing. The answer is a stream, so it is a function that both
///    listens and yields.
Stream<int> everyOther(Stream<int> feed) {
  throw UnimplementedError('challenge 1');
}

/// 2. How many values arrive before one reaches [limit].
///
///    `countUntil` on 5, 7, 40, 9 with a limit of 40 is `2` — the two that
///    came first. When nothing reaches the limit it is the length of the
///    whole feed.
///
///    The feed must not be asked for anything after the answer is known. The
///    test reads [log] to check.
Future<int> countUntil(Stream<int> feed, int limit) {
  throw UnimplementedError('challenge 2');
}

/// 3. The total and the count of one feed.
///
///    `feed.fold(…)` listens once and `feed.length` listens once, so a
///    solution using both is a `StateError`. One pass has to answer both.
Future<(int total, int count)> summaryOf(Stream<int> feed) {
  throw UnimplementedError('challenge 3');
}
