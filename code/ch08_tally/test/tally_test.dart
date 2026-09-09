import 'package:ch08_tally/tally.dart';
import 'package:test/test.dart';

void main() {
  group('tally', () {
    test('counts repeats', () {
      expect(tally(['red', 'blue', 'red']), {'red': 2, 'blue': 1});
    });

    test('an empty list tallies to an empty map', () {
      expect(tally([]), <String, int>{});
    });
  });

  // #region lookup
  group('reading a map back', () {
    final counts = tally(['red', 'blue', 'red']);

    test('a key that is there gives its value', () {
      expect(counts['red'], 2);
    });

    test('a key that is not there gives null, not an error', () {
      expect(counts['green'], isNull);
    });

    test('containsKey asks without reading', () {
      expect(counts.containsKey('green'), isFalse);
      expect(counts.containsKey('red'), isTrue);
    });
  });
  // #endregion lookup

  group('map order and size', () {
    test('a map literal keeps the order keys were first inserted', () {
      final counts = tally(['pear', 'apple', 'pear', 'fig']);
      expect(counts.keys.toList(), ['pear', 'apple', 'fig']);
    });

    test('length counts keys, not words', () {
      expect(tally(['red', 'red', 'red']).length, 1);
    });
  });

  // #region sets
  group('sets', () {
    test('drops duplicates and keeps first-seen order', () {
      expect(unique(['red', 'blue', 'red']), {'red', 'blue'});
    });

    test('shared keeps only what is in both', () {
      expect(shared({'a', 'b', 'c'}, {'b', 'c', 'd'}), {'b', 'c'});
    });

    test('exclusive keeps only what is in one', () {
      expect(exclusive({'a', 'b', 'c'}, {'b', 'c', 'd'}), {'a', 'd'});
    });

    test('== on a set is identity, exactly as it is on a list', () {
      expect({'a', 'b'} == {'b', 'a'}, isFalse);
      expect([1, 2] == [1, 2], isFalse);
    });

    test('the matcher compares contents, and ignores order only for a set', () {
      expect({'a', 'b'}, equals({'b', 'a'}));
      expect([1, 2], equals([1, 2]));
      expect([1, 2], isNot(equals([2, 1])));
    });
  });
  // #endregion sets
}
