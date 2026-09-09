import 'package:ch19_pence/pence.dart';
import 'package:test/test.dart';

void main() {
  test('an int can say what it is worth', () {
    expect(1234.asMoney, '£12.34');
    expect(5.asMoney, '£0.05');
  });

  test('and whether it is money going out', () {
    expect((-250).asMoney, '-£2.50');
    expect((-250).isDebit, isTrue);
    expect(250.isDebit, isFalse);
  });
}
