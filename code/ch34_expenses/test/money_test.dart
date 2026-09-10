import 'package:ch34_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  test('an amount is the pence it was made from', () {
    expect(Money.fromPence(1250).pence, 1250);
  });

  test('pounds and pence read the way a person says them', () {
    expect(Money.fromPence(1250).asText, '£12.50');
    expect(Money.fromPence(5).asText, '£0.05');
    expect(Money.fromPence(0).asText, '£0.00');
  });

  test('a negative amount is refused, and says why', () {
    expect(
      () => Money.fromPence(-1),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'money is never negative',
        ),
      ),
    );
  });
}
