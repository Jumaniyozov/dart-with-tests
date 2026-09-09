import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — how many words', () {
    test('adds every count', () {
      expect(totalWords({'red': 2, 'blue': 1}), 3);
    });

    test('an empty tally counts nothing', () {
      expect(totalWords({}), 0);
    });
  });

  group('challenge 2 — the most common word', () {
    test('finds the highest count', () {
      expect(mostCommon({'red': 2, 'blue': 1}), 'red');
      expect(mostCommon({'blue': 1, 'red': 9, 'fig': 4}), 'red');
    });

    test('keeps the first word when counts tie', () {
      expect(mostCommon({'red': 2, 'blue': 2}), 'red');
    });

    test('an empty tally has no most common word', () {
      expect(mostCommon({}), '');
    });
  });

  group('challenge 3 — adding tallies', () {
    test('adds counts for words in both', () {
      expect(merged({'red': 2}, {'red': 1, 'blue': 4}), {'red': 3, 'blue': 4});
    });

    test('leaves both maps it was given alone', () {
      final a = {'red': 2};
      final b = {'red': 1};
      merged(a, b);
      expect(a, {'red': 2});
      expect(b, {'red': 1});
    });
  });
}
