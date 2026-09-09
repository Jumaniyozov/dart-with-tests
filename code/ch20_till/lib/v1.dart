import 'till.dart';

// #region copied
/// The same handler, written the way that throws the evidence away.
///
/// The suppression below is not advice. `use_rethrow_when_possible` is on in
/// this book and it is right. It is switched off for one line so that 20.3 can
/// measure what ignoring it costs.
int logged(String typed, List<String> log) {
  try {
    final pence = penceFrom(typed);
    log.add('read $typed');
    return pence;
  } on FormatException catch (error) {
    log.add('refused $typed');
    // ignore: use_rethrow_when_possible
    throw error;
  } finally {
    log.add('done $typed');
  }
}
// #endregion copied

// #region lost
/// A `return` in a `finally` clause, and what it does to the exception.
///
/// `control_flow_in_finally` is on in this book and is right. It is switched
/// off for one line so that 20.3 can measure what ignoring it costs.
int lost(String typed) {
  try {
    return penceFrom(typed);
  } finally {
    // ignore: control_flow_in_finally
    return 0;
  }
}
// #endregion lost
