import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a value', () {
    test('is normalised on the way in', () {
      expect(Postcode('  sw1a  1aa ').value, 'SW1A 1AA');
      expect(Postcode('SW1A 1AA').value, 'SW1A 1AA');
    });

    test('so two spellings are equal, and hash the same', () {
      expect(Postcode('sw1a 1aa'), Postcode('SW1A  1AA'));
      expect(Postcode('sw1a 1aa').hashCode, Postcode('SW1A  1AA').hashCode);
    });

    test('and one map key, not two', () {
      final seen = <Postcode, int>{};
      seen[Postcode('sw1a 1aa')] = 1;
      seen[Postcode('SW1A 1AA')] = 2;
      expect(seen, hasLength(1));
      expect(seen.values.single, 2);
    });

    test('with nothing in it, it is refused', () {
      expect(() => Postcode('   '), throwsArgumentError);
    });
  });

  group('challenge 2 — an entity', () {
    test('is the same receipt when the id matches, whatever else says', () {
      expect(Receipt('r1', 500), Receipt('r1', 900));
      expect(Receipt('r1', 500).hashCode, Receipt('r1', 900).hashCode);
    });

    test('and a different receipt when it does not', () {
      expect(Receipt('r1', 500) == Receipt('r2', 500), isFalse);
    });

    test('so a set keyed on them counts ids, not totals', () {
      expect({Receipt('r1', 500), Receipt('r1', 900)}, hasLength(1));
      expect({Receipt('r1', 500), Receipt('r2', 500)}, hasLength(2));
    });
  });

  group('challenge 3 — a basket that does not leak', () {
    test('changing the list you handed in does not change the basket', () {
      final mine = ['apple'];
      final basket = Basket(mine);
      mine.add('stolen');
      expect(basket.items, ['apple']);
    });

    test('and the list it hands back cannot be added to', () {
      final basket = Basket(['apple']);
      expect(() => basket.items.add('stolen'), throwsUnsupportedError);
    });
  });
}
