import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — the cheapest price', () {
    test('finds the lowest', () {
      expect(cheapest([250, 180, 320]), 180);
      expect(cheapest([99]), 99);
    });

    test('an empty basket costs nothing', () {
      expect(cheapest([]), 0);
    });
  });

  group('challenge 2 — dropping the free items', () {
    test('removes every zero', () {
      expect(withoutFree([250, 0, 180]), [250, 180]);
      expect(withoutFree([0, 0]), <int>[]);
    });

    test('leaves the original list alone', () {
      final original = [250, 0, 180];
      withoutFree(original);
      expect(original, [250, 0, 180]);
    });
  });

  group('challenge 3 — delivery', () {
    test('charges delivery on a small basket', () {
      expect(withDelivery([250, 180], 1000, 99), [250, 180, 99]);
    });

    test('gives free delivery once the basket is big enough', () {
      expect(withDelivery([900, 200], 1000, 99), [900, 200]);
      expect(withDelivery([1000], 1000, 99), [1000]);
    });
  });
}
