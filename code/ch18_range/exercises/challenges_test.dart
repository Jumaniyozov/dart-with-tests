import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — where each value was first seen', () {
    test('keeps the first position and ignores later ones', () {
      expect(firstSeenAt(['a', 'b', 'a']), {'a': 0, 'b': 1});
      expect(firstSeenAt([7, 7, 8]), {7: 0, 8: 2});
    });

    test('and hands back a map typed by what went in', () {
      expect(firstSeenAt(<String>[]), <String, int>{});
      expect(firstSeenAt(['a']), isA<Map<String, int>>());
      expect(firstSeenAt([1]), isNot(isA<Map<String, int>>()));
    });
  });

  group('challenge 2 — a box with a limit', () {
    test('takes things until it is full', () {
      final box = Slots<String>(2);
      expect(box.add('a'), isTrue);
      expect(box.add('b'), isTrue);
      expect(box.add('c'), isFalse);
      expect(box.held, ['a', 'b']);
    });

    test('and it is typed by what it holds', () {
      expect(Slots<int>(1).held, isA<List<int>>());
      expect(Slots<int>(1).held, isNot(isA<List<String>>()));
    });
  });

  group('challenge 3 — the largest value under a limit', () {
    test('finds it for numbers and for words', () {
      expect(highestUnder([3, 9, 2], 9), 3);
      expect(highestUnder(['ant', 'cat', 'bee'], 'cat'), 'bee');
    });

    test('and answers nothing when there is none', () {
      expect(highestUnder([9, 10], 9), isNull);
      expect(highestUnder(<int>[], 5), isNull);
    });
  });
}
