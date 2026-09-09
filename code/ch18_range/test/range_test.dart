import 'package:ch18_range/range.dart';
import 'package:ch18_range/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region oneshape
  group('one piece of code, many types', () {
    test('the bound is what lets it compare at all', () {
      expect(Range(100, 500).contains(500), isTrue);
      expect(Range('ant', 'cat').overlaps(Range('bee', 'dog')), isTrue);
      expect(Range(1, 2).overlaps(Range(5, 6)), isFalse);
    });

    test('and it still refuses to be built backwards', () {
      expect(() => Range(500, 100), throwsA(isA<AssertionError>()));
      expect(() => Range('z', 'a'), throwsA(isA<AssertionError>()));
      expect(Range(3, 3).contains(3), isTrue);
    });

    test('a generic function does the same for study 8 counting', () {
      expect(tallyOf(['a', 'b', 'a']), {'a': 2, 'b': 1});
      expect(tallyOf([1, 1, 1]), {1: 3});
      expect(tallyOf(<String>[]), <String, int>{});
    });

    test('and a bound on a function works the same way', () {
      expect(largestOf([3, 9, 2]), 9);
      expect(largestOf(['ant', 'cat', 'bee']), 'cat');
    });
  });
  // #endregion oneshape

  // #region reified
  group('the type argument is still there when the program runs', () {
    test('a list knows what it was made to hold', () {
      // Held as Object so the analyzer cannot answer the question statically
      // and the check has to happen while the program runs.
      final Object prices = <int>[250, 180];
      expect(prices.runtimeType.toString(), 'List<int>');
      expect(prices is List<int>, isTrue);
      expect(prices is List<String>, isFalse);
    });

    test('a List<int> is a List<num>, because int is a num', () {
      final Object prices = <int>[250, 180];
      expect(prices is List<num>, isTrue);
    });

    test('but seeing it as one does not make it one', () {
      final prices = <int>[250, 180];
      final List<num> asNumbers = prices;
      expect(asNumbers.runtimeType.toString(), 'List<int>');
      expect(() => asNumbers.add(1.5), throwsA(isA<TypeError>()));
      expect(prices, [250, 180]);
    });

    test('two lists of different types are different types', () {
      expect(<int>[].runtimeType == <String>[].runtimeType, isFalse);
    });
  });
  // #endregion reified

  // #region bound
  group('the bound you would write first', () {
    test('silently widens a range of ints to a range of nums', () {
      expect(v1.Range(100, 500).runtimeType.toString(), 'Range<num>');
      expect(v1.Range('ant', 'cat').runtimeType.toString(), 'Range<String>');
    });

    test('because of what int actually implements', () {
      final Object one = 1;
      expect(one is Comparable<num>, isTrue);
      expect(one is Comparable<int>, isFalse);

      final Object word = 'a';
      expect(word is Comparable<String>, isTrue);
    });

    test('and the widening breaks the function outright at run time', () {
      expect(() => v1.largestOf([3, 9, 2]), throwsA(isA<TypeError>()));
      expect(v1.largestOf(['ant', 'cat']), 'cat');
    });

    test('while Comparable<Object> handles both', () {
      expect(largestOf([3, 9, 2]), 9);
      expect(largestOf(['ant', 'cat']), 'cat');
    });
  });
  // #endregion bound

  // #region ours
  group('our own generic types are reified too', () {
    test('a Range of numbers is not a Range of words', () {
      expect(Range(1, 5), isA<Range<num>>());
      expect(Range(1, 5), isNot(isA<Range<String>>()));
    });

    test('this Range keeps the type it was given', () {
      expect(Range(100, 500).runtimeType.toString(), 'Range<int>');
      expect(Range('ant', 'cat').runtimeType.toString(), 'Range<String>');
    });

    test('and the map a generic function built knows its own types', () {
      expect(tallyOf(['a']), isA<Map<String, int>>());
      expect(tallyOf([1]), isNot(isA<Map<String, int>>()));
    });
  });
  // #endregion ours
}
