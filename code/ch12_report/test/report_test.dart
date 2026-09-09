import 'package:ch12_report/report.dart';
import 'package:test/test.dart';

void main() {
  const day = [2500, -900, 0, -150, 400];

  // #region folding
  group('folding a list down to one value', () {
    test('fold carries a running answer and starts from a seed', () {
      expect(total(day), 1850);
      expect(creditsIn(day), 2900);
    });

    test('reduce has no seed, so it has no answer for nothing', () {
      expect(largest(day), 2500);
      expect(() => largest([]), throwsA(isA<StateError>()));
      expect(total([]), 0);
    });
  });
  // #endregion folding

  // #region shaping
  group('reshaping a list', () {
    test('map does not hand back a list', () {
      expect(lines(day), isNot(isA<List<String>>()));
      expect(lines(day).toList(), ['+2500p', '-900p', '0p', '-150p', '+400p']);
    });

    test('expand runs several lists together', () {
      expect(
        everyEntry([
          [1, 2],
          [],
          [3],
        ]).toList(),
        [1, 2, 3],
      );
    });

    test('skip and take cut a window out of the middle', () {
      expect(page(day, skip: 1, take: 2).toList(), [-900, 0]);
      expect(page(day).toList(), [2500, -900, 0]);
      expect(page(day, skip: 99).toList(), <int>[]);
    });
  });
  // #endregion shaping

  // #region asking
  group('asking a list a question', () {
    test('any and every stop as soon as they know', () {
      expect(hasDebit(day), isTrue);
      expect(hasDebit([1, 2]), isFalse);
      expect(allUsed(day), isFalse);
      expect(allUsed([1, -2]), isTrue);
    });

    test('an empty list is true for every and false for any', () {
      expect(hasDebit([]), isFalse);
      expect(allUsed([]), isTrue);
    });

    test('firstWhere replaces study 10 nested loops and its label', () {
      expect(firstShared([30, 10], [99, 10, 30]), 30);
      expect(firstShared([1, 2], [3, 4]), -1);
    });
  });
  // #endregion asking

  // #region lazy
  group('nothing runs until something asks', () {
    test('building a chain does no work at all', () {
      var calls = 0;
      [1, 2, 3].map((n) {
        calls++;
        return n * 2;
      });
      expect(calls, 0);
    });

    test('asking for one element does the work for one element', () {
      var calls = 0;
      final doubled = [1, 2, 3].map((n) {
        calls++;
        return n * 2;
      });
      expect(doubled.first, 2);
      expect(calls, 1);
    });

    test('walking the same chain twice does the work twice', () {
      var calls = 0;
      final doubled = [1, 2, 3].map((n) {
        calls++;
        return n * 2;
      });
      doubled.toList();
      expect(calls, 3);
      doubled.toList();
      expect(calls, 6);
    });

    test('take and skip defer too, and stop as soon as they have enough', () {
      var calls = 0;
      final firstOdd = [1, 2, 3, 4, 5]
          .where((n) {
            calls++;
            return n.isOdd;
          })
          .take(1);

      expect(calls, 0);
      expect(firstOdd.toList(), [1]);
      expect(calls, 1);
    });

    test('length walks the whole chain, isNotEmpty stops at the first', () {
      var calls = 0;
      final odds = [1, 2, 3].where((n) {
        calls++;
        return n.isOdd;
      });

      expect(odds.length, 2);
      expect(calls, 3);

      calls = 0;
      expect(odds.isNotEmpty, isTrue);
      expect(calls, 1);
    });

    test('toList does the work once and keeps the answers', () {
      var calls = 0;
      final settled = [1, 2, 3].map((n) {
        calls++;
        return n * 2;
      }).toList();
      expect(calls, 3);
      settled.toList();
      settled.toList();
      expect(calls, 3);
    });
  });
  // #endregion lazy
}
