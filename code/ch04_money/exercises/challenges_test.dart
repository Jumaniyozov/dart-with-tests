import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a discount', () {
    test('takes a tenth off a round amount', () {
      expect(applyDiscount(1000, 10), 900);
    });

    test('rounds the discount down, never up', () {
      expect(applyDiscount(999, 10), 900);
      expect(applyDiscount(1099, 33), 737);
    });
  });

  group('challenge 2 — a signed amount', () {
    test('puts the minus before the pound sign', () {
      expect(formatSigned(-150), '-£1.50');
    });

    test('leaves a positive amount alone', () {
      expect(formatSigned(150), '£1.50');
      expect(formatSigned(0), '£0.00');
    });
  });

  group('challenge 3 — rounding to five pence', () {
    test('rounds down below the halfway point', () {
      expect(roundToNearest5(1237), 1235);
    });

    test('rounds up from the halfway point', () {
      expect(roundToNearest5(1238), 1240);
      expect(roundToNearest5(1233), 1235);
    });
  });
}
