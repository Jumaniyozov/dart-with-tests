// #region declined
/// The machine said no. This is about the card, not about the code.
class const CardDeclined(final String why) implements Exception {
  @override
  String toString() => 'CardDeclined: $why';
}
// #endregion declined

// #region authorise
/// What the card machine says about [pence], once it has said it.
///
/// [Future.delayed] stands in for a machine on the end of a wire. The delay is
/// one millisecond so the tests stay quick; the shape is the same at one
/// millisecond and at three seconds.
Future<int> authorise(int pence) async {
  if (pence <= 0) {
    throw ArgumentError.value(pence, 'pence', 'a payment must be positive');
  }
  await Future<void>.delayed(const Duration(milliseconds: 1));
  if (pence > 50000) {
    throw const CardDeclined('over the floor limit');
  }
  return pence;
}
// #endregion authorise

// #region take
/// Takes a payment and says what happened.
///
/// The `await` is doing two jobs: it hands back the `int` inside the future,
/// and it puts the failure back inside this `try`.
Future<String> takePayment(int pence) async {
  try {
    final authorised = await authorise(pence);
    return 'authorised $authorised';
  } on CardDeclined catch (error) {
    return 'declined: ${error.why}';
  }
}
// #endregion take

// #region steps
/// Records the start and the end of one slow step in [log].
Future<void> step(String name, List<String> log) async {
  log.add('$name start');
  await Future<void>.delayed(const Duration(milliseconds: 5));
  log.add('$name end');
}

/// Two steps, one after the other.
Future<List<String>> oneAtATime() async {
  final log = <String>[];
  await step('a', log);
  await step('b', log);
  return log;
}

/// The same two steps, both out at once.
Future<List<String>> together() async {
  final log = <String>[];
  await Future.wait([step('a', log), step('b', log)]);
  return log;
}
// #endregion steps
