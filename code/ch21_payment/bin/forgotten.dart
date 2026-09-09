import 'package:ch21_payment/v1.dart' as v1;

/// A payment the card machine will refuse, handled by a `try` that has
/// already finished by the time the refusal arrives.
Future<void> main() async {
  print(await v1.takePayment(90000));
  await Future<void>.delayed(const Duration(milliseconds: 20));
  print('the program is still running');
}
