import 'package:ch16_entries/entries.dart';
import 'package:test/test.dart';

void main() {
  test('each kind of entry says its own thing', () {
    expect(describe(Payment(-2500, 'landlord')), 'paid landlord');
    expect(describe(Refund(1200, 'shop')), 'refund from shop');
  });

  test('and they all answer the question the family asks', () {
    expect(Payment(-2500, 'landlord').isDebit, isTrue);
    expect(Refund(1200, 'shop').isDebit, isFalse);
  });
}
