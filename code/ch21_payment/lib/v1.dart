import 'payment.dart';

// #region forgotten
/// The same handler with the `await` left out.
///
/// `authorise` hands back a future immediately and fails a millisecond later,
/// by which time this function has returned and the `try` is over. The `on`
/// clause is not wrong. It is simply no longer running.
Future<String> takePayment(int pence) async {
  try {
    authorise(pence);
    return 'authorised';
  } on CardDeclined catch (error) {
    return 'declined: ${error.why}';
  }
}
// #endregion forgotten
