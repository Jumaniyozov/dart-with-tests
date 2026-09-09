// #region fault
/// A till reported something that cannot be true.
class const TillFault(final String why) implements Exception {
  @override
  String toString() => 'TillFault: $why';
}
// #endregion fault

// #region feed
/// The amounts a till sends, one at a time.
///
/// `async*` makes a function that hands back a [Stream] rather than a
/// [Future], and `yield` puts one value on it. [log] records when this body
/// actually runs, which is the point of 22.2.
Stream<int> feedOf(List<int> pence, List<String> log) async* {
  log.add('feed started');
  for (final amount in pence) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    log.add('sending $amount');
    yield amount;
  }
  log.add('feed done');
}
// #endregion feed

// #region totals
/// Everything on [feed], added up.
///
/// `await for` takes one value each time round, pausing the function in
/// between exactly as study 21's `await` does.
Future<int> totalOf(Stream<int> feed) async {
  var total = 0;
  await for (final amount in feed) {
    total += amount;
  }
  return total;
}

/// The balance after each amount, sent on as it arrives.
///
/// A function that both listens and yields: a stream in, a stream out.
Stream<int> runningTotalOf(Stream<int> feed) async* {
  var total = 0;
  await for (final amount in feed) {
    total += amount;
    yield total;
  }
}
// #endregion totals

// #region sync
/// The same running total over amounts that are already here.
///
/// `sync*` hands back an [Iterable] and `async*` hands back a [Stream]. It is
/// study 12's laziness with a keyword on it: nothing in this body runs until
/// something asks for a value.
Iterable<int> runningTotals(List<int> pence) sync* {
  var total = 0;
  for (final amount in pence) {
    total += amount;
    yield total;
  }
}
// #endregion sync

// #region verbs
/// The first three payments of a pound or more, as they arrive.
///
/// Every name here is study 12's. A [Stream] answers to the same verbs an
/// [Iterable] does; what changed is that `where` is now deciding about values
/// that have not been sent yet.
Stream<int> largeIn(Stream<int> feed) =>
    feed.where((amount) => amount >= 1000).take(3);
// #endregion verbs

// #region leaving
/// The first payment of a pound or more, or nothing.
///
/// Leaving an `await for` — by `return` here, or by `break` — cancels the
/// subscription, and the feed stops being asked for values.
Future<int?> firstLargeIn(Stream<int> feed) async {
  await for (final amount in feed) {
    if (amount >= 1000) {
      return amount;
    }
  }
  return null;
}
// #endregion leaving

// #region trouble
/// A feed with a till that reports something impossible.
Stream<int> feedWithFault(List<int> pence) async* {
  for (final amount in pence) {
    if (amount < 0) {
      throw TillFault('a till reported $amount');
    }
    yield amount;
  }
}

/// Everything on [feed] up to the fault, and what the fault was.
Future<(int total, String? fault)> totalUntilFault(Stream<int> feed) async {
  var total = 0;
  try {
    await for (final amount in feed) {
      total += amount;
    }
  } on TillFault catch (error) {
    return (total, error.why);
  }
  return (total, null);
}
// #endregion trouble

// #region every
/// Every large amount from a list that is already here, as a stream.
///
/// `yield` sends one value; `yield*` sends every value from another stream.
/// It is the distinction study 7 drew between `add` and the spread `...`.
Stream<int> largeFrom(List<int> pence) async* {
  yield* Stream<int>.fromIterable(pence.where((amount) => amount >= 1000));
}
// #endregion every
