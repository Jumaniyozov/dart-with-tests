import 'package:ch09_lookup/lookup.dart';
import 'package:test/test.dart';

void main() {
  // #region answers
  group('answering the question', () {
    test('?? supplies a value when there is none', () {
      expect(extensionOr('ada', 0), 101);
      expect(extensionOr('mallory', 0), 0);
    });

    test('?. asks only if there is something to ask', () {
      final somebody = nameAt(102);
      final nobody = nameAt(999);
      expect(somebody?.length, 5);
      expect(nobody?.length, isNull);
    });

    test('??= fills a name in only when it is empty', () {
      var found = nameAt(101);
      found ??= 'nobody';
      expect(found, 'ada');

      var missing = nameAt(999);
      missing ??= 'nobody';
      expect(missing, 'nobody');
    });
  });
  // #endregion answers

  // #region promotion
  group('what the analyzer can prove', () {
    test('a checked variable is promoted for the rest of the block', () {
      expect(describe('grace'), 'grace has 5 letters');
      expect(describe(null), 'nobody');
    });
  });
  // #endregion promotion

  group('nameAt', () {
    test('finds a name by extension', () {
      expect(nameAt(102), 'grace');
    });

    test('has nothing for an extension nobody has', () {
      expect(nameAt(999), isNull);
    });
  });

  group('reading typed input', () {
    test('reads a number', () {
      expect(penceFrom('250'), 250);
      expect(penceFrom('  250  '), 250);
    });

    test('falls back when the text is not a number', () {
      expect(penceFrom('two fifty'), 0);
      expect(penceFrom(''), 0);
      expect(penceFrom('12.5'), 0);
      expect(penceFrom('abc', fallback: -1), -1);
    });
  });

  // #region roster
  group('rosterFor', () {
    test('keeps the extensions it finds and drops the rest', () {
      expect(rosterFor(['ada', 'mallory', 'alan']), [101, 103]);
    });

    test('an empty roster is empty, not null', () {
      expect(rosterFor(['mallory']), <int>[]);
    });
  });
  // #endregion roster
}
