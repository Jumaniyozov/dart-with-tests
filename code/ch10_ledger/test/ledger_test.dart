import 'package:ch10_ledger/ledger.dart';
import 'package:ch10_ledger/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region walking
  /// One day's entries, in pence: two in, two out, and a zero.
  const day = [2500, -900, 0, -150, 400];

  group('two ways to walk the same list', () {
    test('the index and the entry reach the same balance', () {
      expect(total(day), totalIn(day));
      expect(total(day), 1850);
    });

    test('both agree on an empty ledger', () {
      expect(total([]), 0);
      expect(totalIn([]), 0);
    });
  });
  // #endregion walking

  // #region leaving
  group('leaving a loop early', () {
    test('stops at the entry that overdraws the account', () {
      expect(firstOverdraft([100, -50, -200, 5000]), 2);
    });

    test('reports -1 when the balance never goes below zero', () {
      expect(firstOverdraft(day), -1);
      expect(firstOverdraft([]), -1);
    });

    test('continue skips the entries it is not counting', () {
      expect(creditsIn(day), 2900);
      expect(creditsIn([-1, -2]), 0);
    });

    test('a labelled break leaves both loops, not just the inner one', () {
      // 30 matches first, even though 10 would match later in `theirs`.
      expect(firstShared([30, 10], [99, 10, 30]), 30);
      expect(firstShared([1, 2], [3, 4]), isNull);
    });

    test(
      'without the label the outer loop runs on and keeps the last match',
      () {
        int? shared;
        for (final entry in [30, 10]) {
          for (final other in [99, 10, 30]) {
            if (entry == other) {
              shared = entry;
              break;
            }
          }
        }

        expect(shared, 10);
        expect(shared, isNot(firstShared([30, 10], [99, 10, 30])));
      },
    );
  });
  // #endregion leaving

  // #region width
  group('a loop whose body must run at least once', () {
    test('do-while gives zero a width of one', () {
      expect(digitsIn(0), 1);
      expect(digitsIn(7), 1);
      expect(digitsIn(250), 3);
    });

    test('the while version has no width for zero at all', () {
      expect(v1.digitsIn(0), 0);
      expect(v1.digitsIn(250), 3);
    });
  });
  // #endregion width

  // #region guard
  group('the guard on a width', () {
    test('a negative amount trips the assert under the test runner', () {
      expect(() => digitsIn(-250), throwsA(isA<AssertionError>()));
    });

    test('an unguarded loop takes a negative amount and answers nonsense', () {
      expect(-250 ~/ 10, -25);
      expect(v1.digitsIn(-250), 0);
    });
  });
  // #endregion guard

  // #region kinds
  group('switch, doing and producing', () {
    test('the expression form hands back a heading', () {
      expect(labelFor(2500), 'in');
      expect(labelFor(-900), 'out');
      expect(labelFor(0), 'nil');
    });

    test('the statement form changes three separate totals', () {
      expect(countByKind(day), {
        Kind.credit: 2,
        Kind.debit: 2,
        Kind.nothing: 1,
      });
    });

    test('a case does not run on into the next one', () {
      // Five entries, and each is counted exactly once. Under C-style
      // fall-through a credit would land in all three totals and these
      // would add up to fifteen.
      final counted = countByKind(day);
      expect(counted.values.fold(0, (a, b) => a + b), day.length);
    });
  });
  // #endregion kinds
}
