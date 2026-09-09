import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — every other value', () {
    test('keeps the first, the third and the fifth', () async {
      expect(await everyOther(feedOf([1, 2, 3, 4, 5], [])).toList(), [1, 3, 5]);
      expect(await everyOther(feedOf([1, 2], [])).toList(), [1]);
    });

    test('and an empty feed sends nothing', () async {
      expect(await everyOther(feedOf([], [])).toList(), isEmpty);
    });
  });

  group('challenge 2 — how many came first', () {
    test('counts what arrived before the limit was reached', () async {
      expect(await countUntil(feedOf([5, 7, 40, 9], []), 40), 2);
      expect(await countUntil(feedOf([100], []), 40), 0);
    });

    test('and counts the whole feed when nothing reaches it', () async {
      expect(await countUntil(feedOf([1, 2, 3], []), 40), 3);
    });

    test('and stops asking once it knows', () async {
      final log = <String>[];
      await countUntil(feedOf([5, 7, 40, 9], log), 40);
      expect(log, ['sending 5', 'sending 7', 'sending 40']);
    });
  });

  group('challenge 3 — two answers, one listen', () {
    test('adds up and counts in a single pass', () async {
      expect(await summaryOf(feedOf([700, 250, 1000], [])), (1950, 3));
      expect(await summaryOf(feedOf([], [])), (0, 0));
    });
  });
}
