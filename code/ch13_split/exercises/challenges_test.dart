import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — minutes and seconds', () {
    test('splits a duration into both halves', () {
      expect(asMinutes(125), (2, 5));
      expect(asMinutes(30), (0, 30));
    });

    test('a whole number of minutes has no seconds left over', () {
      expect(asMinutes(120), (2, 0));
      expect(asMinutes(0), (0, 0));
    });
  });

  group('challenge 2 — what came in and what went out', () {
    test('reports both, both positive', () {
      expect(flows([100, -30, 50]), (inward: 150, outward: 30));
    });

    test('a ledger with nothing in it has nothing either way', () {
      expect(flows([]), (inward: 0, outward: 0));
      expect(flows([0]), (inward: 0, outward: 0));
    });
  });

  group('challenge 3 — the first thing said twice', () {
    test('gives the value and where it was first seen', () {
      expect(firstRepeat([5, 9, 5]), (5, 0));
      expect(firstRepeat([1, 2, 2, 1]), (2, 1));
    });

    test('nothing repeated is nothing', () {
      expect(firstRepeat([1, 2, 3]), isNull);
      expect(firstRepeat([]), isNull);
    });
  });
}
