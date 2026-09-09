import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — what went out', () {
    test('writes the debits as positive amounts, in order', () {
      expect(refunds([100, -250, -5]).toList(), ['250p', '5p']);
    });

    test('a ledger with nothing going out has no refunds', () {
      expect(refunds([100, 200]).toList(), <String>[]);
      expect(refunds([]).toList(), <String>[]);
    });
  });

  group('challenge 2 — the busiest day', () {
    test('finds the day that adds up to the most', () {
      expect(
        biggestDay([
          [10, 10],
          [50],
        ]),
        50,
      );
      expect(
        biggestDay([
          [10, 10, 10],
          [5],
          [-100],
        ]),
        30,
      );
    });

    test('an empty week has no busiest day', () {
      expect(biggestDay([]), 0);
    });
  });

  group('challenge 3 — the biggest top-ups', () {
    test('takes at most three, in the order they appear', () {
      expect(topUps([100, 500, 20, 700, 900, 1000], 400), [500, 700, 900]);
      expect(topUps([100, 500], 400), [500]);
    });

    test('nothing over the threshold is an empty list', () {
      expect(topUps([1, 2, 3], 400), <int>[]);
    });
  });
}
