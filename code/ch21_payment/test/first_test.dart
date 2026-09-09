import 'package:ch21_payment/payment.dart';
import 'package:test/test.dart';

void main() {
  test('a payment the machine allows', () async {
    expect(await takePayment(1234), 'authorised 1234');
  });

  test('and one it does not', () async {
    expect(await takePayment(90000), 'declined: over the floor limit');
  });
}
