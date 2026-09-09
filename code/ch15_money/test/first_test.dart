import 'package:ch15_money/money.dart';
import 'package:test/test.dart';

void main() {
  test('an amount knows how to write itself out', () {
    expect(Money(250).format(), '£2.50');
  });

  test('and money going out says so', () {
    expect(Money(-250).format(), '-£2.50');
  });
}
