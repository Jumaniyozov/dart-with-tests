import 'package:ch04_money/money.dart';
import 'package:test/test.dart';

void main() {
  group('total', () {
    test('multiplies a price by a quantity', () {
      expect(total(10, 3), 30);
    });

    test('costs nothing when you buy nothing', () {
      expect(total(1099, 0), 0);
    });
  });

  group('format', () {
    test('splits pence into pounds and pence', () {
      expect(format(1234), '£12.34');
    });

    test('pads a single digit of pence', () {
      expect(format(1205), '£12.05');
    });

    test('writes a whole number of pounds', () {
      expect(format(1200), '£12.00');
    });

    test('writes less than a pound', () {
      expect(format(7), '£0.07');
    });
  });
}
