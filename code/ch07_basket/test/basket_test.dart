import 'package:ch07_basket/basket.dart';
import 'package:test/test.dart';

void main() {
  group('totalOf', () {
    test('adds every price', () {
      expect(totalOf([250, 180, 320]), 750);
    });

    test('an empty basket costs nothing', () {
      expect(totalOf([]), 0);
    });
  });

  // #region mutability
  group('final and const', () {
    test('final stops the name moving, not the list changing', () {
      final prices = [250, 180];
      prices.add(320);
      expect(prices, [250, 180, 320]);
      // prices = [1]; // would not compile: final means assigned once.
    });

    test('const freezes the list itself, and says so at run time', () {
      expect(
        () => standardPrices.add(999),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('two identical const lists are one object, not two', () {
      const a = [1, 2];
      const b = [1, 2];
      expect(identical(a, b), isTrue);
    });

    test('a fixed-length list refuses to grow, with its own message', () {
      final fixed = List<int>.filled(2, 0);
      fixed[0] = 99;
      expect(fixed, [99, 0]);
      expect(
        () => fixed.add(1),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            'Cannot add to a fixed-length list',
          ),
        ),
      );
    });

    test('two identical ordinary lists are two objects', () {
      final a = [1, 2];
      final b = [1, 2];
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
  // #endregion mutability

  group('basket', () {
    test('is the standard prices when nothing is chosen', () {
      expect(basket(), [250, 180, 320]);
    });

    test('adds the deluxe item when asked', () {
      expect(basket(deluxe: true), [250, 180, 320, 500]);
    });

    test('adds delivery only when there is a charge', () {
      expect(basket(deliveryPence: 99), [250, 180, 320, 99]);
      expect(basket(deliveryPence: 0), [250, 180, 320]);
    });
  });

  group('raisedBy', () {
    test('raises every price and rounds down', () {
      expect(raisedBy([250, 180, 320], 10), [275, 198, 352]);
      expect(raisedBy([99], 10), [108]);
    });
  });
}
