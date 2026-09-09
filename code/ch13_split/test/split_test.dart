import 'package:ch13_split/split.dart';
import 'package:test/test.dart';

void main() {
  // #region equality
  group('a record is equal to another record with the same fields', () {
    test('two records built separately are equal', () {
      expect((1, 2) == (1, 2), isTrue);
      expect((1, 2) == (2, 1), isFalse);
    });

    test('equal, but not the same object', () {
      expect(identical((1, 2), (1, 2)), isFalse);
    });

    test('the same two numbers in a list are not equal at all', () {
      expect([1, 2] == [1, 2], isFalse);
    });

    test(
      'named fields are matched by name, not by the order you wrote them',
      () {
        expect((pounds: 1, pence: 2) == (pence: 2, pounds: 1), isTrue);
      },
    );
  });
  // #endregion equality

  // #region key
  group('which is what makes a record usable as a key', () {
    test('equal records have equal hash codes', () {
      expect((1, 2).hashCode, (1, 2).hashCode);
    });

    test('a map looks a record up by its fields', () {
      expect(tallySplits([1234, 1234, 7]), {(12, 34): 2, (0, 7): 1});
    });
  });
  // #endregion key

  // #region reading
  group('reading the fields', () {
    test(r'positional fields are $1 and $2', () {
      final split = splitPence(1234);
      expect(split.$1, 12);
      expect(split.$2, 34);
    });

    test('named fields are read by their names', () {
      final money = breakDown(1234);
      expect(money.pounds, 12);
      expect(money.pence, 34);
    });

    test('or you can take the whole thing apart in one line', () {
      final (pounds, pence) = splitPence(1234);
      expect(pounds, 12);
      expect(pence, 34);
    });

    test('a name on a positional field is a note, not a getter', () {
      final range = rangeOf([5, -2, 9]);
      expect(range.$1, -2);
      expect(range.$2, 9);
    });
  });
  // #endregion reading

  // #region using
  group('using the split', () {
    test('formats an amount from both halves', () {
      expect(format(1234), '£12.34');
      expect(format(1200), '£12.00');
      expect(format(7), '£0.07');
    });
  });
  // #endregion using
}
