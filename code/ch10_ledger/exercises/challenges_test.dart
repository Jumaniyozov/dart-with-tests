import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — the balance after each entry', () {
    test('reports the balance line by line', () {
      expect(runningBalance([100, -30, 5]), [100, 70, 75]);
    });

    test('an empty ledger has no history', () {
      expect(runningBalance([]), <int>[]);
    });
  });

  group('challenge 2 — the longest run of money coming in', () {
    test('counts the longest unbroken run', () {
      expect(longestRun([100, 200, -50, 300]), 2);
      expect(longestRun([100, 200, 300]), 3);
    });

    test('a debit or a blank line ends the run', () {
      expect(longestRun([100, 0, 200]), 1);
      expect(longestRun([-1, -2]), 0);
      expect(longestRun([]), 0);
    });
  });

  group('challenge 3 — making an amount out of coins', () {
    test('uses the fewest coins it can', () {
      expect(coinsNeeded(260), 3);
      expect(coinsNeeded(288), 7);
      expect(coinsNeeded(200), 1);
      expect(coinsNeeded(3), 2);
    });

    test('nothing needs no coins', () {
      expect(coinsNeeded(0), 0);
    });
  });
}
